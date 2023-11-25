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
    
    var playing: Set<Layer.ID> { Set(activeNodes.keys) }
    private let engine: AVAudioEngine
    private var activeNodes: [Layer.ID: AudioEnginePlayerNodeProtocol]
    private let makePlayerNode: (Data) -> AudioEnginePlayerNodeProtocol?
    
    init(makePlayerNode: @escaping (Data) -> AudioEnginePlayerNodeProtocol?) {
        
        self.engine = AVAudioEngine()
        self.makePlayerNode = makePlayerNode
        self.activeNodes = [:]
    }
    
    func play(id: Layer.ID, data: Data, control: Layer.Control) {
        
        guard let playerNode = makePlayerNode(data) else {
            return
        }
        
        playerNode.connect(to: engine)
        playerNode.play()
        activeNodes[id] = playerNode
    }
}

protocol AudioEnginePlayerNodeProtocol {
    
    init?(with data: Data)
    func connect(to engine: AVAudioEngine)
    func play()
}

final class AudioEnginePlayerTests: XCTestCase {
    
    private var playerNodeSpy: AudioEnginePlayerNodeSpy?
    
    override func setUp() async throws {
        try await super.setUp()
        
        playerNodeSpy = nil
    }
    
    func test_init_nothingPlaying() {
        
        let sut = makeSUT()
        
        XCTAssertTrue(sut.playing.isEmpty)
    }
    
    func test_play_nothingPlayingOnNodeCreationFailure() {
        
        let sut = AudioEnginePlayer(makePlayerNode: { data in
            AlwaysFailingAudioEnginePlayerNodeStub(with: data)
        })
        
        sut.play(id: anyLayerID(), data: anyData(), control: .initial)
        
        XCTAssertTrue(sut.playing.isEmpty)
    }
    
    func test_play_invokesPlayerNodeConnectToEngineAndPlayMethodsOnNodeCreationSuccess() {
        
        let sut = makeSUT()
        
        let data = anyData()
        sut.play(id: anyLayerID(), data: data, control: .initial)
        
        XCTAssertEqual(playerNodeSpy?.messages, [.initWithData(data), .connectToEngine, .play])
    }
    
    func test_play_playingContainsLayerIDOnNodeCreationSuccess() {
        
        let sut = makeSUT()
        
        let layerID = anyLayerID()
        sut.play(id: layerID, data: anyData(), control: .initial)
        
        XCTAssertTrue(sut.playing.contains(layerID))
    }

    //MARK: - Helpers
    
    private func makeSUT(
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> AudioEnginePlayer {
        
        let sut = AudioEnginePlayer(makePlayerNode: { data in
            
            self.playerNodeSpy = AudioEnginePlayerNodeSpy(with: data)
            return self.playerNodeSpy
        })
        
        trackForMemoryLeaks(sut, file: file, line: line)
        
        return sut
    }
    
    private class AudioEnginePlayerNodeSpy: AudioEnginePlayerNodeProtocol {
        
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
    
    private class AlwaysFailingAudioEnginePlayerNodeStub: AudioEnginePlayerNodeProtocol {
        
        required init?(with data: Data) {
            
            return nil
        }
        
        func connect(to engine: AVAudioEngine) {}
        
        func play() {}
    }
}
