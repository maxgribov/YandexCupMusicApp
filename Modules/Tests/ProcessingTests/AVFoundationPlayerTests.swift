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
    
    @discardableResult
    func play() -> Bool
    
    var volume: Float { get set }
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
        player.play()
        activePlayers[id] = player
    }
}

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
        
        sut.play(id: anyLayerID(), data: anyData(), control: .init(volume: 0.5, speed: 1))
        
        XCTAssertEqual(player?.volume, 0.5)
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
        
        enum Message: Equatable {
            
            case initWithData(Data)
            case play
        }
        
        required init(data: Data) throws {
            
            messages.append(.initWithData(data))
        }
        
        @discardableResult
        func play() -> Bool {
            
            messages.append(.play)
            return true
        }
    }
    
    class AlwaysFailingAVAudioPlayerStub: AVAudioPlayerProtocol {
        
        var volume: Float = 1.0
        
        required init(data: Data) throws {
            
            throw NSError(domain: "", code: 0)
        }
        
        @discardableResult
        func play() -> Bool { false }
    }
    
    private func anyLayerID() -> Layer.ID { UUID() }
    private func anyData() -> Data { Data(UUID().uuidString.utf8) }
}

extension AVAudioPlayer: AVAudioPlayerProtocol {}
