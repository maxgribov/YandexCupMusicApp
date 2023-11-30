//
//  AudioEnginePlayer.swift
//
//
//  Created by Max Gribov on 26.11.2023.
//

import AVFoundation
import Domain

public final class AudioEnginePlayer<Node>: Player where Node: AudioEnginePlayerNodeProtocol {
    
    public var playing: Set<Layer.ID> { Set(activeNodes.keys) }
    private let engine: AVAudioEngine
    private var activeNodes: [Layer.ID: Node]
    private let makePlayerNode: (Data) -> Node?
    private var event: ((TimeInterval?) -> Void)?
    
    public init(engine: AVAudioEngine, makePlayerNode: @escaping (Data) -> Node?) {
        
        self.engine = engine
        self.makePlayerNode = makePlayerNode
        self.activeNodes = [:]
    }
    
    public func playing(event: @escaping (TimeInterval?) -> Void) {
        
        self.event = event
    }
    
    public func play(id: Layer.ID, data: Data, control: Layer.Control) {

        guard let playerNode = makePlayerNode(data) else {
            return
        }
        
        playerNode.connect(to: engine)
        playerNode.set(volume: Float(control.volume))
        playerNode.set(rate: control.rate)
        
        if let firstPlayerNode = activeNodes.first?.value {
            
            playerNode.schedule(offset: firstPlayerNode.offset)
            
        } else {
            
            playerNode.schedule(offset: nil)
        }
        
        if engine.isRunning == false {
            
            try? engine.start()
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
        playerNode.set(rate: control.rate)
    }
}
