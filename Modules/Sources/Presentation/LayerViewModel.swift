//
//  File.swift
//  
//
//  Created by Max Gribov on 31.10.2023.
//

import Foundation
import Domain
import Producer
import Combine

public struct LayerViewModel: Identifiable {

    public let id: Layer.ID
    public let name: String
    public let isPlaying: Bool
    public let isMuted: Bool
    public let isActive: Bool
    
    public let delegateActionSubject = PassthroughSubject<DelegateAction, Never>()
    
    public init(id: Layer.ID, name: String, isPlaying: Bool, isMuted: Bool, isActive: Bool) {
        
        self.id = id
        self.name = name
        self.isPlaying = isPlaying
        self.isMuted = isMuted
        self.isActive = isActive
    }
    
    public init(with layer: Layer, isActive: Bool) {
        
        self.init(id: layer.id, name: layer.name, isPlaying: layer.isPlaying, isMuted: layer.isMuted, isActive: isActive)
    }
    
    public func playButtonDidTaped() {
        
        delegateActionSubject.send(.isPlayingDidChanged(!isPlaying))
    }
    
    public func muteButtonDidTapped() {
        
        delegateActionSubject.send(.isMutedDidChanged(!isMuted))
    }
    
    public func selectDidTapped() {
        
        delegateActionSubject.send(.selectLayer)
    }
    
    public func deleteButtonDidTapped() {
        
        delegateActionSubject.send(.deleteLayer)
    }
}

public extension LayerViewModel {
    
    enum DelegateAction: Equatable {
        
        case isPlayingDidChanged(Bool)
        case isMutedDidChanged(Bool)
        case selectLayer
        case deleteLayer
    }
}
