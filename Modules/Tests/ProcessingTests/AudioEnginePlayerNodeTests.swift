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
    private let buffer: AVAudioPCMBuffer
    
    init(player: AVAudioPlayerNode, speedControl: AVAudioUnitVarispeed, buffer: AVAudioPCMBuffer) {
        
        self.player = player
        self.speedControl = speedControl
        self.buffer = buffer
    }
    
    func connect(to engine: AVAudioEngine) {
        
        engine.attach(player)
        engine.attach(speedControl)
        engine.connect(player, to: speedControl, format: nil)
        engine.connect(speedControl, to: engine.mainMixerNode, format: nil)
    }
    
    func disconnect(from engine: AVAudioEngine) {
        
        engine.disconnectNodeInput(speedControl)
        engine.disconnectNodeInput(player)
        engine.detach(speedControl)
        engine.detach(player)
    }
    
    func schedule(offset: AVAudioTime?) {
        
        player.scheduleBuffer(buffer, at: offset, options: .loops)
    }
    
    func play() {
        
        player.play()
    }
}

final class AudioEnginePlayerNodeTests: XCTestCase {
    
    func test_init_doesNotMessagesPlayerAndSpeedControl() {
        
        let (_, player, speedControl, _) = makeSUT()
        
        XCTAssertTrue(player.messages.isEmpty)
        XCTAssertTrue(speedControl.messages.isEmpty)
    }
    
    func test_connectToEngine_messagesEngine() {
        
        let (sut, player, speedControl, _) = makeSUT()
        
        let engineSpy = AVAudioEngineSpy()
        sut.connect(to: engineSpy)
        
        XCTAssertEqual(engineSpy.messages, [.attach(player), .attach(speedControl), .connect(player, speedControl), .connect(speedControl, engineSpy.mainMixerNode)])
    }
    
    func test_disconnectFromEngine_messagesEngine() {
        
        let (sut, player, speedControl, _) = makeSUT()
        
        let engineSpy = AVAudioEngineSpy()
        sut.disconnect(from: engineSpy)
        
        XCTAssertEqual(engineSpy.messages, [.disconnect(speedControl), .disconnect(player), .detach(speedControl), .detach(player)])
    }
    
    func test_schedule_messagesPlayerToScheduleBuffer() {
        
        let (sut, player, _, buffer) = makeSUT()
        
        sut.schedule(offset: nil)
        
        XCTAssertEqual(player.messages, [.schedule(buffer, nil, .loops)])
    }
    
    func test_scheduleWithOffset_messagesPlayerToScheduleBufferAtSpecificTime() {
        
        let (sut, player, _, buffer) = makeSUT()
        
        let offset = AVAudioTime(sampleTime: 100, atRate: 100)
        sut.schedule(offset: offset)
        
        XCTAssertEqual(player.messages, [.schedule(buffer, offset, .loops)])
    }
    
    func test_play_messagesPayerToPlay() {
        
        let (sut, player, _, _) = makeSUT()
        
        sut.play()
        
        XCTAssertEqual(player.messages, [.play])
    }
    
    //MARK: - Helpers
    
    private func makeSUT(
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> (
        sut: AudioEnginePlayerNode,
        player: AVAudioPlayerNodeSpy,
        speedControl: AVAudioUnitVarispeedSpy,
        buffer: AVAudioPCMBuffer
    ) {
        
        let player = AVAudioPlayerNodeSpy()
        let speedControl = AVAudioUnitVarispeedSpy()
        let buffer = AVAudioPCMBuffer()
        let sut = AudioEnginePlayerNode(player: player, speedControl: speedControl, buffer: buffer)
        
        trackForMemoryLeaks(sut, file: file, line: line)
        trackForMemoryLeaks(player, file: file, line: line)
        trackForMemoryLeaks(speedControl, file: file, line: line)
        trackForMemoryLeaks(buffer, file: file, line: line)
        
        return (sut, player, speedControl, buffer)
    }
    
    class AVAudioPlayerNodeSpy: AVAudioPlayerNode {
        
        private(set) var messages = [Message]()
        
        enum Message: Equatable {
            
            case schedule(AVAudioPCMBuffer, AVAudioTime?, AVAudioPlayerNodeBufferOptions)
            case play
        }
        
        override func scheduleBuffer(_ buffer: AVAudioPCMBuffer, at when: AVAudioTime?, options: AVAudioPlayerNodeBufferOptions = [], completionHandler: AVAudioNodeCompletionHandler? = nil) {
            
            messages.append(.schedule(buffer, when, options))
        }
        
        override func play() {
            
            messages.append(.play)
        }
    }
    
    class AVAudioUnitVarispeedSpy: AVAudioUnitVarispeed {
        
        private(set) var messages = [Any]()
    }
    
    class AVAudioEngineSpy: AVAudioEngine {
        
        private(set) var messages = [Message]()
        
        enum Message: Equatable {
            
            case attach(AVAudioNode)
            case connect(AVAudioNode, AVAudioNode)
            case disconnect(AVAudioNode)
            case detach(AVAudioNode)
        }
        
        override func attach(_ node: AVAudioNode) {
            
            messages.append(.attach(node))
        }
        
        override func connect(_ node1: AVAudioNode, to node2: AVAudioNode, format: AVAudioFormat?) {
            
            messages.append(.connect(node1, node2))
        }
        
        override func disconnectNodeInput(_ node: AVAudioNode) {
            
            messages.append(.disconnect(node))
        }
        
        override func detach(_ node: AVAudioNode) {
            
            messages.append(.detach(node))
        }
    }
}
