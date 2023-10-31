//
//  File.swift
//  
//
//  Created by Max Gribov on 31.10.2023.
//

import Foundation
import Samples
import Combine

public final class LayerViewModel: Identifiable, ObservableObject {

    public let id: Layer.ID
    public let name: String
    @Published public private(set) var isPlaying: Bool
    @Published public private(set) var isMuted: Bool
    @Published public private(set) var isActive: Bool
    
    public let delegateActionSubject = PassthroughSubject<DelegateAction, Never>()
    
    public init(id: Layer.ID, name: String, isPlaying: Bool, isMuted: Bool, isActive: Bool) {
        
        self.id = id
        self.name = name
        self.isPlaying = isPlaying
        self.isMuted = isMuted
        self.isActive = isActive
    }
    
    public convenience init(with layer: Layer, isActive: Bool) {
        
        self.init(id: layer.id, name: layer.name, isPlaying: layer.isPlaying, isMuted: layer.isMuted, isActive: isActive)
    }
    
    public func playButtonDidTaped() {
        
        isPlaying.toggle()
        delegateActionSubject.send(.isPlayingDidChanged(isPlaying))
    }
    
    public func muteButtonDidTapped() {
        
        isMuted.toggle()
        delegateActionSubject.send(.isMutedDidChanged(isMuted))
    }
    
    public func deleteButtonDidTapped() {
        
        delegateActionSubject.send(.deleteLayer)
    }
    
    public func selectDidTapped() {
        
        delegateActionSubject.send(.selectLayer)
    }
    
    public func update(isPlaying: Bool) {
        
        self.isPlaying = isPlaying
    }
    
    public func update(isActive: Bool) {
        
        self.isActive = isActive
    }
}

public extension LayerViewModel {
    
    enum DelegateAction: Equatable {
        
        case isPlayingDidChanged(Bool)
        case isMutedDidChanged(Bool)
        case deleteLayer
        case selectLayer
    }
}
