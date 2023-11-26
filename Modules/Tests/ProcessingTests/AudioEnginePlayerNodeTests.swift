//
//  AudioEnginePlayerNodeTests.swift
//  
//
//  Created by Max Gribov on 26.11.2023.
//

import XCTest
import AVFoundation

final class AudioEnginePlayerNode {
    
    private let player: AVAudioPlayerNode
    private let speedControl: AVAudioUnitVarispeed
    
    init(player: AVAudioPlayerNode, speedControl: AVAudioUnitVarispeed) {
        
        self.player = player
        self.speedControl = speedControl
    }
    
    func connect(to engine: AVAudioEngine) {
        
        engine.attach(player)
        engine.attach(speedControl)
        engine.connect(player, to: speedControl, format: nil)
        engine.connect(speedControl, to: engine.mainMixerNode, format: nil)
    }
}

final class AudioEnginePlayerNodeTests: XCTestCase {
    
    func test_init_doesNotMessagesPlayerAndSpeedControl() {
        
        let (_, player, speedControl) = makeSUT()
        
        XCTAssertTrue(player.messages.isEmpty)
        XCTAssertTrue(speedControl.messages.isEmpty)
    }
    
    func test_connectToEngine_messagesEngine() {
        
        let (sut, player, speedControl) = makeSUT()
        
        let engineSpy = AVAudioEngineSpy()
        sut.connect(to: engineSpy)
        
        XCTAssertEqual(engineSpy.messages, [.attach(player), .attach(speedControl), .connect(player, speedControl), .connect(speedControl, engineSpy.mainMixerNode)])
    }
    
    //MARK: - Helpers
    
    private func makeSUT(
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> (
        sut: AudioEnginePlayerNode,
        player: AVAudioPlayerNodeSpy,
        speedControl: AVAudioUnitVarispeedSpy
    ) {
        
        let player = AVAudioPlayerNodeSpy()
        let speedControl = AVAudioUnitVarispeedSpy()
        let sut = AudioEnginePlayerNode(player: player, speedControl: speedControl)
        
        trackForMemoryLeaks(sut, file: file, line: line)
        trackForMemoryLeaks(player, file: file, line: line)
        trackForMemoryLeaks(speedControl, file: file, line: line)
        
        return (sut, player, speedControl)
    }
    
    class AVAudioPlayerNodeSpy: AVAudioPlayerNode {
        
        private(set) var messages = [Any]()
    }
    
    class AVAudioUnitVarispeedSpy: AVAudioUnitVarispeed {
        
        private(set) var messages = [Any]()
    }
    
    class AVAudioEngineSpy: AVAudioEngine {
        
        private(set) var messages = [Message]()
        
        enum Message: Equatable {
            
            case attach(AVAudioNode)
            case connect(AVAudioNode, AVAudioNode)
        }
        
        override func attach(_ node: AVAudioNode) {
            
            messages.append(.attach(node))
        }
        
        override func connect(_ node1: AVAudioNode, to node2: AVAudioNode, format: AVAudioFormat?) {
            
            messages.append(.connect(node1, node2))
        }
    }
}
