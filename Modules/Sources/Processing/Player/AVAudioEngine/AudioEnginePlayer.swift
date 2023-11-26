//
//  AudioEnginePlayer.swift
//
//
//  Created by Max Gribov on 26.11.2023.
//

import AVFoundation
import Domain

public final class AudioEnginePlayer<Node> where Node: AudioEnginePlayerNodeProtocol {
    
    public var playing: Set<Layer.ID> { Set(activeNodes.keys) }
    private let engine: AVAudioEngine
    private var activeNodes: [Layer.ID: Node]
    private let makePlayerNode: (Data) -> Node?
    private var event: ((TimeInterval?) -> Void)?
    
    public init(engine: AVAudioEngine, makePlayerNode: @escaping (Data) -> Node?) {
        
        self.engine = engine
        self.makePlayerNode = makePlayerNode
        self.activeNodes = [:]
        
        engine.prepare()
    }
    
    public func playing(event: @escaping (TimeInterval?) -> Void) {
        
        self.event = event
    }
    
    public func play(id: Layer.ID, data: Data, control: Layer.Control) {
        
        if engine.isRunning == false {
            
            try? engine.start()
        }
        
        guard let playerNode = makePlayerNode(data) else {
            return
        }
        
        playerNode.connect(to: engine)
        playerNode.set(volume: Float(control.volume))
        playerNode.set(rate: Self.rate(from: control.speed))
        
        if let firstPlayerNode = activeNodes.first?.value {
            
            playerNode.set(offset: firstPlayerNode.offset)
        }
        
        playerNode.play()
        
        if activeNodes.isEmpty {
            
            event?(playerNode.duration)
        }
        
        activeNodes[id] = playerNode
    }
    
    public func stop(id: Layer.ID) {
        
        guard let playerNode = activeNodes[id] else {
            return
        }
        
        activeNodes.removeValue(forKey: id)
        playerNode.stop()
        playerNode.disconnect(from: engine)
        
        if activeNodes.isEmpty {
            
            event?(nil)
        }
    }
    
    public func update(id: Layer.ID, with control: Layer.Control) {
        
        guard let playerNode = activeNodes[id] else {
            return
        }
        
        playerNode.set(volume: Float(control.volume))
        playerNode.set(rate: Self.rate(from: control.speed))
    }
}

extension AudioEnginePlayer {
    
    static func rate(from speed: Double) -> Float {
        
        let _speed = min(max(speed, 0), 1)
        
        return Float(((2.0 - 0.5) * _speed) + 0.5)
    }
}