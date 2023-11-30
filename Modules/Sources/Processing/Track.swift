//
//  Track.swift
//
//
//  Created by Max Gribov on 28.11.2023.
//

import Foundation
import Domain

public struct Track: Equatable {
    
    public let id: UUID
    public let data: Data
    public let volume: Float
    public let rate: Float
    
    public init(id: UUID, data: Data, volume: Float, rate: Float) {
     
        self.id = id
        self.data = data
        self.volume = volume
        self.rate = rate
    }
    
    public init(with layer: Layer, data: Data) {
        
        self.init(id: layer.id, data: data, volume: Float(layer.control.volume), rate: layer.control.rate)
    }
}
