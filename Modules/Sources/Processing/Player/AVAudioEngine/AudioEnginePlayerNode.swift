//
//  AudioEnginePlayerNode.swift
//  
//
//  Created by Max Gribov on 26.11.2023.
//

import AVFoundation

public final class AudioEnginePlayerNode {
    
    private let player: AVAudioPlayerNode
    private let speedControl: AVAudioUnitVarispeed
    private let buffer: AVAudioPCMBuffer
    
    public var offset: AVAudioTime { Self.offset(current: player.current, duration: duration, sampleRate: player.outputFormat(forBus: 0).sampleRate) }
    public var duration: TimeInterval { Self.duration(for: buffer.frameLength, and: buffer.format.sampleRate) }
    
    public init(player: AVAudioPlayerNode, speedControl: AVAudioUnitVarispeed, buffer: AVAudioPCMBuffer) {
        
        self.player = player
        self.speedControl = speedControl
        self.buffer = buffer
    }
    
    public func connect(to engine: AVAudioEngine) {
        
        engine.attach(player)
        engine.attach(speedControl)
        engine.connect(player, to: speedControl, format: nil)
        engine.connect(speedControl, to: engine.mainMixerNode, format: nil)
    }
    
    public func disconnect(from engine: AVAudioEngine) {
        
        engine.disconnectNodeInput(speedControl)
        engine.disconnectNodeInput(player)
        engine.detach(speedControl)
        engine.detach(player)
    }
    
    public func schedule(offset: AVAudioTime?) {
        
        player.scheduleBuffer(buffer, at: offset, options: .loops)
    }
    
    public func play() {
        
        player.play()
    }
    
    public func stop() {
        
        player.stop()
    }
    
    public func set(volume: Float) {
        
        player.volume = volume
    }
    
    public func set(rate: Float) {
        
        speedControl.rate = rate
    }
}

public extension AudioEnginePlayerNode {
    
    static func duration(for frameLength: AVAudioFrameCount, and sampleRate: Double) -> TimeInterval {
        
        TimeInterval(Double(frameLength) / sampleRate)
    }
    
    static func offset(current: TimeInterval, duration: TimeInterval, sampleRate: Double) -> AVAudioTime {
        
        let offsetTime = current.truncatingRemainder(dividingBy: duration)
        
        return AVAudioTime(sampleTime: -Int64(offsetTime * sampleRate), atRate: sampleRate)
    }
}

public extension AVAudioPlayerNode {

    var current: TimeInterval {
        
        guard let nodeTime = lastRenderTime, let playerTime = playerTime(forNodeTime: nodeTime) else {
            return 0
        }
        
        return Double(playerTime.sampleTime) / playerTime.sampleRate
    }
}
