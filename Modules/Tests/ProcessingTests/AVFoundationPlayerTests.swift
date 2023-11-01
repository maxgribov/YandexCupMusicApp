//
//  AVFoundationPlayerTests.swift
//  
//
//  Created by Max Gribov on 01.11.2023.
//

import XCTest
import Domain
import Processing
import AVFoundation

protocol AVAudioPlayerProtocol: AnyObject {
    
    init(data: Data) throws

    var volume: Float { get set }
    var enableRate: Bool { get set }
    var rate: Float { get set }
    var numberOfLoops: Int { get set }
    var currentTime: TimeInterval { get set }
    
    @discardableResult
    func play() -> Bool
    func stop()
}

final class AVFoundationPlayer {
    
    var playing: Set<Layer.ID> { Set(activePlayers.keys) }
    
    private var activePlayers: [Layer.ID: any AVAudioPlayerProtocol]
    private let makePlayer: (Data) throws -> any AVAudioPlayerProtocol
    
    init(makePlayer: @escaping (Data) throws -> any AVAudioPlayerProtocol) {
        
        self.activePlayers = [:]
        self.makePlayer = makePlayer
    }
    
    func play(id: Layer.ID, data: Data, control: Layer.Control) {
        
        guard let player = try? makePlayer(data) else {
            return
        }
        
        player.volume = Float(control.volume)
        player.enableRate = true
        player.rate = Self.rate(from: control.speed)
        player.numberOfLoops = Self.playForever
        player.play()
        activePlayers[id] = player
    }
    
    func stop(id: Layer.ID) {
        
        activePlayers[id]?.stop()
        activePlayers[id] = nil
    }
}

extension AVFoundationPlayer {
    
    static func rate(from speed: Double) -> Float {
        
        let _speed = min(max(speed, 0), 1)
        
        return Float(((2.0 - 0.5) * _speed) + 0.5)
    }
    
    static let playForever: Int = -1
}

extension AVAudioPlayer: AVAudioPlayerProtocol {}

final class AVFoundationPlayerTests: XCTestCase {
    
    var player: AVAudioPlayerSpy? = nil
    
    override func setUp() async throws {
        try await super.setUp()
        
        player = nil
    }
    
    func test_init_nothingPlaying() {
        
        let sut = makeSUT()
        
        XCTAssertTrue(sut.playing.isEmpty)
    }
    
    func test_play_nothingPlayingOnPlayerInitFailure() {
        
        let sut = AVFoundationPlayer { data in
            try AlwaysFailingAVAudioPlayerStub(data: data)
        }
        
        sut.play(id: anyLayerID(), data: anyData(), control: .initial)
        
        XCTAssertTrue(sut.playing.isEmpty)
    }
    
    func test_play_invokesPlayOnPlayerSuccessfulInit() {
        
        let sut = makeSUT()
        
        let data = anyData()
        sut.play(id: anyLayerID(), data: data, control: .initial)
        
        XCTAssertEqual(self.player?.messages, [.initWithData(data), .play])
    }
    
    func test_play_addLayerIDToPlayingOnPlayerSuccessInit() {
        
        let sut = makeSUT()
        
        let layerID = anyLayerID()
        sut.play(id: layerID, data: anyData(), control: .initial)
        
        XCTAssertEqual(sut.playing, [layerID])
    }
    
    func test_play_setVolumeAccordingControlVolumeValues() {
        
        let sut = makeSUT()
        
        sut.play(id: anyLayerID(), data: anyData(), control: .init(volume: 0.5, speed: 0.5))
        
        XCTAssertEqual(player?.volume, 0.5)
    }
    
    func test_play_setEnableRateToTrue() {
        
        let sut = makeSUT()
        
        sut.play(id: anyLayerID(), data: anyData(), control: .initial)
        
        XCTAssertEqual(player?.enableRate, true)
    }
    
    func test_rateFromSpeed_correctCalculations() {
        
        XCTAssertEqual(AVFoundationPlayer.rate(from: 0), 0.5, accuracy: .ulpOfOne)
        XCTAssertEqual(AVFoundationPlayer.rate(from: 1), 2, accuracy: .ulpOfOne)
        XCTAssertEqual(AVFoundationPlayer.rate(from: 0.5), 1.25, accuracy: .ulpOfOne)
        XCTAssertEqual(AVFoundationPlayer.rate(from: 0.34), 1.01, accuracy: .ulpOfOne)
        
        XCTAssertEqual(AVFoundationPlayer.rate(from: -1), 0.5, accuracy: .ulpOfOne)
        XCTAssertEqual(AVFoundationPlayer.rate(from: 10), 2, accuracy: .ulpOfOne)
    }
    
    func test_play_setRateToValueCalculatedFromSpeed() {
        
        let sut = makeSUT()
        
        sut.play(id: anyLayerID(), data: anyData(), control: .init(volume: 1.0, speed: 1.0))
        
        XCTAssertEqual(player?.rate, 2.0)
    }
    
    func test_play_setNumberOfLoopsToPlayForever() {
        
        let sut = makeSUT()
        
        sut.play(id: anyLayerID(), data: anyData(), control: .initial)
        
        XCTAssertEqual(player?.numberOfLoops, playForeverValue())
    }
    
    func test_stop_doesNotAffectPlayingValueOnIncorrectLayerID() {
        
        let sut = makeSUT()
        let layerID = anyLayerID()
        sut.play(id: layerID, data: anyData(), control: .initial)
        XCTAssertEqual(sut.playing, [layerID])
        
        sut.stop(id: anyLayerID())
        
        XCTAssertEqual(sut.playing, [layerID])
    }
    
    func test_stop_removesLayerIDFromPlayingValue() {
        
        let sut = makeSUT()
        let layerID = anyLayerID()
        sut.play(id: layerID, data: anyData(), control: .initial)
        XCTAssertEqual(sut.playing, [layerID])
        
        sut.stop(id: layerID)
        
        XCTAssertTrue(sut.playing.isEmpty)
    }
    
    func test_stop_invokesStopMethodOnPlayer() {
        
        let sut = makeSUT()
        let layerID = anyLayerID()
        let data = anyData()
        sut.play(id: layerID, data: data, control: .initial)
        XCTAssertEqual(sut.playing, [layerID])
        
        sut.stop(id: layerID)
        
        XCTAssertEqual(self.player?.messages, [.initWithData(data), .play, .stop])
    }
    
    func test_play_doesNotChangeCurrentTimeValueForFirstPlayer() {
        
        let sut = makeSUT()
        
        sut.play(id: anyLayerID(), data: anyData(), control: .initial)
        
        XCTAssertEqual(player?.currentTime, AVAudioPlayerSpy.defaultCurrentTimeValue)
    }
    
    //MARK: - Helpers
    
    private func makeSUT(
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> AVFoundationPlayer {
        
        let sut = AVFoundationPlayer {[weak self] data in
            let _player = try AVAudioPlayerSpy(data: data)
            self?.player = _player
            return _player
        }
        trackForMemoryLeaks(sut, file: file, line: line)
        
        return sut
    }
    
    class AVAudioPlayerSpy: AVAudioPlayerProtocol {
        
        private(set) var messages = [Message]()
        var volume: Float = 1.0
        var enableRate: Bool = false
        var rate: Float = 1.0
        var numberOfLoops: Int = 0
        var currentTime: TimeInterval = AVAudioPlayerSpy.defaultCurrentTimeValue
        
        enum Message: Equatable {
            
            case initWithData(Data)
            case play
            case stop
        }
        
        required init(data: Data) throws {
            
            messages.append(.initWithData(data))
        }
        
        @discardableResult
        func play() -> Bool {
            
            messages.append(.play)
            return true
        }
        
        func stop() {
            
            messages.append(.stop)
        }
        
        static let defaultCurrentTimeValue: TimeInterval = 0
    }
    
    class AlwaysFailingAVAudioPlayerStub: AVAudioPlayerProtocol {
        
        var volume: Float = 1.0
        var enableRate: Bool = false
        var rate: Float = 1.0
        var numberOfLoops: Int = 0
        var currentTime: TimeInterval = 0
        
        required init(data: Data) throws {
            
            throw NSError(domain: "", code: 0)
        }
        
        @discardableResult
        func play() -> Bool { false }
        
        func stop() {}
    }
    
    private func anyLayerID() -> Layer.ID { UUID() }
    private func anyData() -> Data { Data(UUID().uuidString.utf8) }
    private func playForeverValue() -> Int { AVFoundationPlayer.playForever }
}


