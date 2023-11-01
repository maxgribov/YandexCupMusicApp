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

final class AVFoundationPlayer {
    
    private(set) var playing: Set<Layer.ID>
    
    init() {
        
        self.playing = []
    }
}

final class AVFoundationPlayerTests: XCTestCase {

    func test_init_nothingPlaying() {
        
        let sut = AVFoundationPlayer()
        
        XCTAssertTrue(sut.playing.isEmpty)
    }
}
