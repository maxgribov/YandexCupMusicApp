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
    private var event: ((TimeInterval?) -> Void)?
    
    public init(makePlayer: @escaping (Data) throws -> P) {
        
        self.activePlayers = [:]
        self.makePlayer = makePlayer
    }
    
    public func playing(event: @escaping (TimeInterval?) -> Void) {
        
        self.event = event
    }
    
    public func play(id: Layer.ID, data: Data, control: Layer.Control) {
        
        guard let player = try? makePlayer(data) else {
            return
        }
        
        player.volume = Float(control.volume)
        player.enableRate = true
        player.rate = control.rate
        player.numberOfLoops = Self.playForever()
        
        if let firstActivePlayer = activePlayers.first?.value {
            
            player.currentTime = firstActivePlayer.currentTime
        }
        
        player.play()
        
        if activePlayers.isEmpty {
            
            event?(player.duration)
        }
        
        activePlayers[id] = player
    }
    
    public func stop(id: Layer.ID) {
        
        activePlayers[id]?.stop()
        activePlayers[id] = nil
        
        if activePlayers.isEmpty {
            
            event?(nil)
        }
    }
    
    public func update(id: Layer.ID, with control: Layer.Control) {
        
        activePlayers[id]?.volume = Float(control.volume)
        activePlayers[id]?.rate = control.rate
    }
}

public extension FoundationPlayer {
    
    static func playForever() -> Int { -1 }
}
