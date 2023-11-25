//
//  AudioEnginePlayerTests.swift
//  
//
//  Created by Max Gribov on 25.11.2023.
//

import XCTest
import Domain
import AVFoundation

final class AudioEnginePlayer {
    
    var playing: Set<Layer.ID> { [] }
    private let engine: AVAudioEngine
    private let makePlayerNode: (Data) -> AudioEnginePlayerNodeProtocol?
    
    init(makePlayerNode: @escaping (Data) -> AudioEnginePlayerNodeProtocol?) {
        
        self.engine = AVAudioEngine()
        self.makePlayerNode = makePlayerNode
    }
    
    func play(id: Layer.ID, data: Data, control: Layer.Control) {
        
        let playerNode = makePlayerNode(data)
        playerNode?.connect(to: engine)
        playerNode?.play()
    }
}

protocol AudioEnginePlayerNodeProtocol {
    
    init?(with data: Data)
    func connect(to engine: AVAudioEngine)
    func play()
}

final class AudioEnginePlayerTests: XCTestCase {
    
    func test_init_nothingPlaying() {
        
        let sut = AudioEnginePlayer(makePlayerNode: { _ in return nil })
        
        XCTAssertTrue(sut.playing.isEmpty)
    }
    
    func test_play_nothingPlayingOnNodeCreationFailure() {
        
        let sut = AudioEnginePlayer(makePlayerNode: { data in
            AlwaysFailingAudioEnginePlayerNodeStub(with: data)
        })
        
        sut.play(id: anyLayerID(), data: anyData(), control: .initial)
        
        XCTAssertTrue(sut.playing.isEmpty)
    }
    
    func test_play_invokesPlayerNodeConnectToEngineAndPlayMethods() {
        
        var playerNodeSpy: AudioEnginePlayerNodeSpy? = nil
        let sut = AudioEnginePlayer(makePlayerNode: { data in
            
            playerNodeSpy = AudioEnginePlayerNodeSpy(with: data)
            return playerNodeSpy
        })
        
        let data = anyData()
        sut.play(id: anyLayerID(), data: data, control: .initial)
        
        XCTAssertEqual(playerNodeSpy?.messages, [.initWithData(data), .connectToEngine, .play])
    }

    //MARK: - Helpers
    
    class AudioEnginePlayerNodeSpy: AudioEnginePlayerNodeProtocol {
        
        private(set) var messages = [Message]()
        
        enum Message: Equatable {
            
            case initWithData(Data)
            case connectToEngine
            case play
        }
        
        required init?(with data: Data) {
            
            messages.append(.initWithData(data))
        }
        
        func connect(to engine: AVAudioEngine) {
            
            messages.append(.connectToEngine)
        }
        
        func play() {
             
            messages.append(.play)
        }
        
    }
    
    class AlwaysFailingAudioEnginePlayerNodeStub: AudioEnginePlayerNodeProtocol {
        
        required init?(with data: Data) {
            
            return nil
        }
        
        func connect(to engine: AVAudioEngine) {}
        
        func play() {}
    }
}
