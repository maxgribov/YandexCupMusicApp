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
    private var event: ((TimeInterval?) -> Void)?
    
    init(makePlayerNode: @escaping (Data) -> AudioEnginePlayerNodeProtocol?) {
        
        self.engine = AVAudioEngine()
        self.makePlayerNode = makePlayerNode
        self.activeNodes = [:]
    }
    
    func playing(event: @escaping (TimeInterval?) -> Void) {
        
        self.event = event
    }
    
    func play(id: Layer.ID, data: Data, control: Layer.Control) {
        
        guard let playerNode = makePlayerNode(data) else {
            return
        }
        
        playerNode.connect(to: engine)
        playerNode.set(volume: Float(control.volume))
        playerNode.set(rate: Self.rate(from: control.speed))
        
        if let firstPlayerNode = activeNodes.first?.value {
            
            playerNode.set(offset: firstPlayerNode.offset)
        }
        
        playerNode.play()
        
        if activeNodes.isEmpty {
            
            event?(playerNode.duration)
        }
        
        activeNodes[id] = playerNode
    }
    
    func stop(id: Layer.ID) {
        
        guard let playerNode = activeNodes[id] else {
            return
        }
        
        activeNodes.removeValue(forKey: id)
        playerNode.stop()
        playerNode.disconnect(from: engine)
        
        if activeNodes.isEmpty {
            
            event?(nil)
        }
    }
    
    func update(id: Layer.ID, with control: Layer.Control) {
        
        guard let playerNode = activeNodes[id] else {
            return
        }
        
        playerNode.set(volume: Float(control.volume))
        playerNode.set(rate: Self.rate(from: control.speed))
    }
}

extension AudioEnginePlayer {
    
    static func rate(from speed: Double) -> Float {
        
        let _speed = min(max(speed, 0), 1)
        
        return Float(((2.0 - 0.5) * _speed) + 0.5)
    }
}

protocol AudioEnginePlayerNodeProtocol {
    
    var offset: AVAudioTime { get }
    var duration: TimeInterval { get }
    
    init?(with data: Data)
    func connect(to engine: AVAudioEngine)
    func disconnect(from engine: AVAudioEngine)
    func play()
    func stop()
    func set(volume: Float)
    func set(rate: Float)
    func set(offset: AVAudioTime)
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
    
    func test_stop_removesExistingLayerIDFromPlaying() {
        
        let sut = makeSUT()
        let layerID = anyLayerID()
        sut.play(id: layerID, data: anyData(), control: .initial)
        XCTAssertTrue(sut.playing.contains(layerID))
        
        sut.stop(id: layerID)
        
        XCTAssertTrue(sut.playing.isEmpty)
    }
    
    func test_stop_invokesPlayerNodeWithStopAnDisconnectFromEngine() {
        
        let sut = makeSUT()
        let layerID = anyLayerID()
        let data = anyData()
        sut.play(id: layerID, data: data, control: .init(volume: 0.5, speed: 1.0))
        XCTAssertTrue(sut.playing.contains(layerID))
        
        sut.stop(id: layerID)
        
        XCTAssertEqual(playerNodeSpy?.messages, [.initWithData(data), .connectToEngine, .setVolume(0.5), .setRate(2.0), .play, .stop, .disconnectFromEngine])
    }
    
    func test_start_invokesSetOffsetOnAnotherPlayerNode() {
        
        let sut = makeSUT()
        sut.play(id: anyLayerID(), data: anyData(), control: .initial)
        
        let firstPlayerNode = playerNodeSpy
        let offset = AVAudioTime(sampleTime: 100, atRate: 50)
        firstPlayerNode?.offsetStub = offset
        
        let data = anyData()
        sut.play(id: anyLayerID(), data: data, control: .init(volume: 0.5, speed: 1.0))
        
        XCTAssertEqual(playerNodeSpy?.messages, [.initWithData(data), .connectToEngine, .setVolume(0.5), .setRate(2.0), .setOffset(offset), .play])
    }
    
    func test_updateWithControl_doesNotAffectOnPlayerNodeForWrongLayerID() {
        
        let sut = makeSUT()
        let data = anyData()
        sut.play(id: anyLayerID(), data: data, control: .init(volume: 0.5, speed: 1.0))
        
        sut.update(id: anyLayerID(), with: .init(volume: 1, speed: 0))
        
        XCTAssertEqual(playerNodeSpy?.messages, [.initWithData(data), .connectToEngine, .setVolume(0.5), .setRate(2.0), .play])
    }
    
    func test_updateWithControl_invokesSetVolumeAndSetRateForCorrectLayerID() {
        
        let sut = makeSUT()
        let layerID = anyLayerID()
        let data = anyData()
        sut.play(id: layerID, data: data, control: .init(volume: 0.5, speed: 1.0))
        
        sut.update(id: layerID, with: .init(volume: 1, speed: 0))
        
        XCTAssertEqual(playerNodeSpy?.messages, [.initWithData(data), .connectToEngine, .setVolume(0.5), .setRate(2.0), .play, .setVolume(1.0), .setRate(0.5)])
    }
    
    func test_playingEvent_deliversPlayerNodeDurationOnFirstLayerPlaying() {
        
        let sut = makeSUT()
        
        expect(sut, playingEvents: [AudioEnginePlayerNodeSpy.durationStub], on: {
            
            sut.play(id: anyLayerID(), data: anyData(), control: .initial)
        })
    }
    
    func test_playingEvent_doesNotDeliverValueOnPlayerNodeStartIfAlreadyAnyNodePlaying() {
        
        let sut = makeSUT()
        sut.play(id: anyLayerID(), data: anyData(), control: .initial)
        
        expect(sut, playingEvents: [], on: {
            
            sut.play(id: anyLayerID(), data: anyData(), control: .initial)
        })
    }
    
    func test_playingEvent_deliverNilValueOnLastPlayerNodeStop() {
        
        let sut = makeSUT()
        let layerID = anyLayerID()
        sut.play(id: layerID, data: anyData(), control: .initial)
        
        expect(sut, playingEvents: [nil], on: {
            
            sut.stop(id: layerID)
        })
    }
    
    func test_playingEvent_doesNotDeliverAnyValueIfAnyPlayerNodeStillPlaying() {
        
        let sut = makeSUT()
        let layerID = anyLayerID()
        sut.play(id: layerID, data: anyData(), control: .initial)
        sut.play(id: anyLayerID(), data: anyData(), control: .initial)
        
        expect(sut, playingEvents: [], on: {
            
            sut.stop(id: layerID)
        })
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
            case setOffset(AVAudioTime)
            case stop
            case disconnectFromEngine
        }
        
        var offsetStub: AVAudioTime?
        var offset: AVAudioTime { offsetStub ?? .init() }
        static let durationStub: TimeInterval = 4.0
        var duration: TimeInterval { Self.durationStub }
        
        required init?(with data: Data) {
            
            messages.append(.initWithData(data))
        }
        
        func connect(to engine: AVAudioEngine) {
            
            messages.append(.connectToEngine)
        }
        
        func disconnect(from engine: AVAudioEngine) {
            
            messages.append(.disconnectFromEngine)
        }
        
        func play() {
             
            messages.append(.play)
        }
        
        func stop() {
            
            messages.append(.stop)
        }
        
        func set(volume: Float) {
            
            messages.append(.setVolume(volume))
        }
        
        func set(rate: Float) {
                
            messages.append(.setRate(rate))
        }
        
        func set(offset: AVAudioTime) {
            
            messages.append(.setOffset(offset))
        }
    }
    
    private class AlwaysFailingAudioEnginePlayerNodeStub: AudioEnginePlayerNodeProtocol {
        
        var offset: AVAudioTime = .init()
        var duration: TimeInterval { 0 }
        
        required init?(with data: Data) {
            
            return nil
        }
        
        func connect(to engine: AVAudioEngine) {}
        func disconnect(from engine: AVAudioEngine) {}
        func play() {}
        func stop() {}
        func set(volume: Float) {}
        func set(rate: Float) {}
        func set(offset: AVAudioTime) {}
    }
    
    private func expect(
        _ sut: AudioEnginePlayer,
        playingEvents expectedPlayingEvents: [TimeInterval?],
        on action: () -> Void,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        
        var receivedEventValues = [TimeInterval?]()
        sut.playing { value in
            receivedEventValues.append(value)
        }
        
        action()
        
        XCTAssertEqual(receivedEventValues, expectedPlayingEvents, file: file, line: line)
    }
}
