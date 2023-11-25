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
}

final class AudioEnginePlayerTests: XCTestCase {

    
    func test_init_nothingPlaying() {
        
        let sut = AudioEnginePlayer()
        
        XCTAssertTrue(sut.playing.isEmpty)
    }

}
