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
    
    var duration: TimeInterval { Self.duration(for: buffer.frameLength, and: buffer.format.sampleRate) }
    
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
    
    func stop() {
        
        player.stop()
    }
    
    func set(volume: Float) {
        
        player.volume = volume
    }
    
    func set(rate: Float) {
        
        speedControl.rate = rate
    }
}

extension AudioEnginePlayerNode {
    
    static func duration(for frameLength: AVAudioFrameCount, and sampleRate: Double) -> TimeInterval {
        
        TimeInterval(Double(frameLength) / sampleRate)
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
