//
//  AudioEnginePlayerTests.swift
//  
//
//  Created by Max Gribov on 25.11.2023.
//

import XCTest
import Domain

final class AudioEnginePlayer {
    
    var playing: Set<Layer.ID> { [] }
    
    init(makePlayerNode: @escaping (Data) -> AudioEnginePlayerNodeProtocol?) {}
    
    func play(id: Layer.ID, data: Data, control: Layer.Control) {}
}

protocol AudioEnginePlayerNodeProtocol {
    
    init?(with data: Data)
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
        
        XCTAssertTrue(sut.playing.isEmpty)
    }

    //MARK: - Helpers
    
    class AlwaysFailingAudioEnginePlayerNodeStub: AudioEnginePlayerNodeProtocol {
        
        required init?(with data: Data) {
            
            return nil
        }
    }
}
