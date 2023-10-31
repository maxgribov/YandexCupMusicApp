//
//  Layer.swift
//
//
//  Created by Max Gribov on 31.10.2023.
//

import Foundation

public struct Layer {

    public typealias ID = UUID
    
    public let id: ID
    public let name: String
    public var isPlaying: Bool
    public var isMuted: Bool
    public var control: Control
    
    public init(id: Layer.ID, name: String, isPlaying: Bool, isMuted: Bool, control: Layer.Control) {
        self.id = id
        self.name = name
        self.isPlaying = isPlaying
        self.isMuted = isMuted
        self.control = control
    }
}

public extension Layer {
    
    struct Control {

        public let volume: Double
        public let speed: Double
        
        public init(volume: Double, speed: Double) {
            
            self.volume = volume
            self.speed = speed
        }
    }
}
