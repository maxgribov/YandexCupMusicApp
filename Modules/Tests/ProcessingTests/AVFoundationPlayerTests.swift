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
        
        let sut = makeSUT()
        
        XCTAssertTrue(sut.playing.isEmpty)
    }
    
    //MARK: - Helpers
    
    private func makeSUT(
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> AVFoundationPlayer {
        
        let sut = AVFoundationPlayer()
        trackForMemoryLeaks(sut)
        
        return sut
    }
}
