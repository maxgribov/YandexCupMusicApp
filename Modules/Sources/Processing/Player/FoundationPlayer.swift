//
//  FoundationPlayer.swift
//
//
//  Created by Max Gribov on 01.11.2023.
//

import AVFoundation
import Domain

public final class FoundationPlayer<P>: Player where P: AVAudioPlayerProtocol {
    
    public var playing: Set<Layer.ID> { Set(activePlayers.keys) }
    
    private var activePlayers: [Layer.ID: P]
    private let makePlayer: (Data) throws -> P
    
    public init(makePlayer: @escaping (Data) throws -> P) {
        
        self.activePlayers = [:]
        self.makePlayer = makePlayer
    }
    
    public func play(id: Layer.ID, data: Data, control: Layer.Control) {
        
        guard let player = try? makePlayer(data) else {
            return
        }
        
        player.volume = Float(control.volume)
        player.enableRate = true
        player.rate = Self.rate(from: control.speed)
        player.numberOfLoops = Self.playForever()
        
        if let firstActivePlayer = activePlayers.first?.value {
            
            player.currentTime = firstActivePlayer.currentTime
        }
        
        player.play()
        activePlayers[id] = player
    }
    
    public func stop(id: Layer.ID) {
        
        activePlayers[id]?.stop()
        activePlayers[id] = nil
    }
}

public extension FoundationPlayer {
    
    static func rate(from speed: Double) -> Float {
        
        let _speed = min(max(speed, 0), 1)
        
        return Float(((2.0 - 0.5) * _speed) + 0.5)
    }
    
    static func playForever() -> Int { -1 }
}