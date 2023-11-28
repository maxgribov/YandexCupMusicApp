//
//  AudioEngineComposerTests.swift
//  
//
//  Created by Max Gribov on 28.11.2023.
//

import XCTest
import AVFoundation

final class AudioEngineComposer {
    
    init(engine: AVAudioEngine) {
        
    }
}

final class AudioEngineComposerTests: XCTestCase {

    func test_init_doesNotMessagesEngine() {
        
        let engine = AVAudioEngineSpy()
        let _ = AudioEngineComposer(engine: engine)
        
        XCTAssertEqual(engine.messages, [])
    }

}
