//
//  AudioEnginePlayerNodeTests.swift
//  
//
//  Created by Max Gribov on 26.11.2023.
//

import XCTest
import AVFoundation

final class AudioEnginePlayerNode {
    
    init(player: AVAudioPlayerNode) {}
}

final class AudioEnginePlayerNodeTests: XCTestCase {
    
    func test_init_doesNotMessagesPlayer() {
        
        let player = AVAudioPlayerNodeSpy()
        let sut = AudioEnginePlayerNode(player: player)
        
        XCTAssertTrue(player.messages.isEmpty)
    }
    
    //MARK: - Helpers
    
    class AVAudioPlayerNodeSpy: AVAudioPlayerNode {
        
        private(set) var messages = [Any]()
    }
}
