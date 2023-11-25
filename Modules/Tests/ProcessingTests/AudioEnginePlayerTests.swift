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
        playerNode.set(volume: Float(control.volume))
        playerNode.set(rate: Self.rate(from: control.speed))
        playerNode.play()
        activeNodes[id] = playerNode
    }
    
    func stop(id: Layer.ID) {
        
        
    }
}

extension AudioEnginePlayer {
    
    static func rate(from speed: Double) -> Float {
        
        let _speed = min(max(speed, 0), 1)
        
        return Float(((2.0 - 0.5) * _speed) + 0.5)
    }
}

protocol AudioEnginePlayerNodeProtocol {
    
    init?(with data: Data)
    func connect(to engine: AVAudioEngine)
    func play()
    func set(volume: Float)
    func set(rate: Float)
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
        sut.play(id: anyLayerID(), data: data, control: .init(volume: 0.5, speed: 1.0))
        
        XCTAssertEqual(playerNodeSpy?.messages, [.initWithData(data), .connectToEngine, .setVolume(0.5), .setRate(2.0), .play])
    }
    
    func test_play_playingContainsLayerIDOnNodeCreationSuccess() {
        
        let sut = makeSUT()
        
        let layerID = anyLayerID()
        sut.play(id: layerID, data: anyData(), control: .initial)
        
        XCTAssertTrue(sut.playing.contains(layerID))
    }
    
    func test_stop_doesNotAffectPlayingOnIncorrectLayerID() {
        
        let sut = makeSUT()
        let layerID = anyLayerID()
        sut.play(id: layerID, data: anyData(), control: .initial)
        XCTAssertTrue(sut.playing.contains(layerID))
        
        sut.stop(id: anyLayerID())
        
        XCTAssertFalse(sut.playing.isEmpty)
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
            case setVolume(Float)
            case setRate(Float)
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
        
        func set(volume: Float) {
            
            messages.append(.setVolume(volume))
        }
        
        func set(rate: Float) {
                
            messages.append(.setRate(rate))
        }
    }
    
    private class AlwaysFailingAudioEnginePlayerNodeStub: AudioEnginePlayerNodeProtocol {
        
        required init?(with data: Data) {
            
            return nil
        }
        
        func connect(to engine: AVAudioEngine) {}
        func play() {}
        func set(volume: Float) {}
        func set(rate: Float) {}
    }
}
