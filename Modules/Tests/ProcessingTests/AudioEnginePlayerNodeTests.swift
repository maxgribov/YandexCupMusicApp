//
//  AudioEnginePlayerNodeTests.swift
//  
//
//  Created by Max Gribov on 26.11.2023.
//

import XCTest
import AVFoundation
import Processing

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
    
    func test_stop_messagesPayerToStop() {
        
        let (sut, player, _, _) = makeSUT()
        
        sut.stop()
        
        XCTAssertEqual(player.messages, [.stop])
    }
    
    func test_setVolume_messagesPlayerToSetVolume() {
        
        let (sut, player, _, _) = makeSUT()
        
        let volume: Float = 0.8
        sut.set(volume: volume)
        
        XCTAssertEqual(player.messages, [.volume(volume)])
    }
    
    func test_setRate_messagesSpeedControlToSetRate() {
        
        let (sut, _, speedControl, _) = makeSUT()
        
        let rate: Float = 0.3
        sut.set(rate: rate)
        
        XCTAssertEqual(speedControl.messages, [.rate(rate)])
    }
    
    func test_duration_retrievesValuesFromBufferAndCalculatesDuration() {
        
        let (sut, _, _, buffer) = makeSUT()
        
        let frameLength: AVAudioFrameCount = 100
        let sampleRate: Double = 50
        let expectedDuration = AudioEnginePlayerNode.duration(for: frameLength, and: sampleRate)
        
        buffer.stub(frameLength: frameLength, sampleRate: sampleRate)
        
        XCTAssertEqual(sut.duration, expectedDuration)
    }
    
    func test_current_deliversCurrentTimeForPlayer() {
        
        let (_, player, _, _) = makeSUT()
        
        let stubTime = AVAudioTime(sampleTime: 100, atRate: 50)
        player.currentTimeStub = stubTime
        
        XCTAssertEqual(player.current, Double(stubTime.sampleTime) / stubTime.sampleRate, accuracy: .ulpOfOne)
    }
    
    func test_offset_deliversOffsetTimeCalculatedWithPlayerAndBuffer() {
        
        let (sut, player, _, buffer) = makeSUT()
        
        let stubTime = AVAudioTime(sampleTime: 1125, atRate: 5)
        let playerSampleRate: Double = 5
        player.currentTimeStub = stubTime
        player.sampleRateStub = playerSampleRate
        
        let bufferFrameLength: AVAudioFrameCount = 100
        let bufferSampleRate: Double = 10
        buffer.stub(frameLength: bufferFrameLength, sampleRate: bufferSampleRate)
        
        let expectedCurrent = Double(stubTime.sampleTime) / stubTime.sampleRate
        let expectedDuration = AudioEnginePlayerNode.duration(for: bufferFrameLength, and: bufferSampleRate)
        let expectedOffset = AudioEnginePlayerNode.offset(current: expectedCurrent, duration: expectedDuration, sampleRate: playerSampleRate)
        
        XCTAssertEqual(sut.offset.sampleTime, expectedOffset.sampleTime)
        XCTAssertEqual(sut.offset.sampleRate, expectedOffset.sampleRate)
    }
    
    //MARK: - Helpers
    
    private func makeSUT(
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> (
        sut: AudioEnginePlayerNode,
        player: AVAudioPlayerNodeSpy,
        speedControl: AVAudioUnitVarispeedSpy,
        buffer: AVAudioPCMBufferStub
    ) {
        
        let player = AVAudioPlayerNodeSpy()
        let speedControl = AVAudioUnitVarispeedSpy()
        let buffer = AVAudioPCMBufferStub()
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
            case stop
            case volume(Float)
        }
        
        override func scheduleBuffer(_ buffer: AVAudioPCMBuffer, at when: AVAudioTime?, options: AVAudioPlayerNodeBufferOptions = [], completionHandler: AVAudioNodeCompletionHandler? = nil) {
            
            messages.append(.schedule(buffer, when, options))
        }
        
        override func play() {
            
            messages.append(.play)
        }
        
        override func stop() {
            
            messages.append(.stop)
        }
        
        override var volume: Float {
            set { 
                messages.append(.volume(newValue))
                _volume = newValue
            }
            get {
                _volume
            }
        }
        
        private var _volume: Float = 0
        
        var currentTimeStub: AVAudioTime?
        
        override var lastRenderTime: AVAudioTime? {
            currentTimeStub
        }
        
        override func playerTime(forNodeTime nodeTime: AVAudioTime) -> AVAudioTime? {
            
            currentTimeStub
        }
        
        var sampleRateStub: Double = 0
        override func outputFormat(forBus bus: AVAudioNodeBus) -> AVAudioFormat {
            
            AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: sampleRateStub, channels: 1, interleaved: false)!
        }
    }
    
    class AVAudioUnitVarispeedSpy: AVAudioUnitVarispeed {
        
        private(set) var messages = [Message]()
        
        enum Message: Equatable {
            
            case rate(Float)
        }
        
        override var rate: Float {
            set {
                messages.append(.rate(newValue))
                _rate = newValue
            }
            get {
                _rate
            }
        }
        
        private var _rate: Float = 0
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
    
    class AVAudioPCMBufferStub: AVAudioPCMBuffer {
        
        override var frameLength: AVAudioFrameCount {
            set { _frameLength = newValue }
            get { _frameLength }
        }
        private var _frameLength: AVAudioFrameCount = 0
        
        override var format: AVAudioFormat {
            formatStub!
        }
        private var formatStub: AVAudioFormat?
        
        func stub(frameLength: AVAudioFrameCount, sampleRate: Double) {
            
            self.frameLength = frameLength
            formatStub = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: sampleRate, channels: 1, interleaved: true)
        }
    }
}
