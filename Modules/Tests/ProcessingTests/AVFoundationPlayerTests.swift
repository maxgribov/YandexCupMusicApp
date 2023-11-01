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

protocol AVAudioPlayerProtocol {
    
    init(data: Data) throws
}

final class AVFoundationPlayer<P: AVAudioPlayerProtocol> {
    
    private(set) var playing: Set<Layer.ID>
    
    init() {
        
        self.playing = []
    }
    
    func play(id: Layer.ID, data: Data, control: Layer.Control) {
        
        guard let player = try? P(data: data) else {
            return
        }
    }
}

final class AVFoundationPlayerTests: XCTestCase {
    
    func test_init_nothingPlaying() {
        
        let sut = makeSUT()
        
        XCTAssertTrue(sut.playing.isEmpty)
    }
    
    func test_play_nothingPlayingOnPlayerInitFailure() {
        
        let sut = AVFoundationPlayer<AlwaysFailingAVAudioPlayerStub>()
        
        XCTAssertTrue(sut.playing.isEmpty)
    }
    
    //MARK: - Helpers
    
    private func makeSUT(
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> AVFoundationPlayer<AVAudioPlayerSpy> {
        
        let sut = AVFoundationPlayer<AVAudioPlayerSpy>()
        trackForMemoryLeaks(sut)
        
        return sut
    }
    
    class AVAudioPlayerSpy: AVAudioPlayerProtocol {
        
        required init(data: Data) throws {
            throw NSError(domain: "", code: 0)
        }
    }
    
    class AlwaysFailingAVAudioPlayerStub: AVAudioPlayerProtocol {
        
        required init(data: Data) throws {
            throw NSError(domain: "", code: 0)
        }
    }
}

extension AVAudioPlayer: AVAudioPlayerProtocol {}
