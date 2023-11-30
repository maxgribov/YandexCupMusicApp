//
//  LayersControlViewModel.swift
//
//
//  Created by Max Gribov on 31.10.2023.
//

import Foundation
import Combine
import Domain

public final class LayersControlViewModel: ObservableObject {
    
    @Published public private(set) var layers: [LayerViewModel]
    private let delegateActionSubject = PassthroughSubject<DelegateAction, Never>()
    private var updatesBinding: AnyCancellable?
    
    public init(initial layers: [LayerViewModel], updates: AnyPublisher<[LayerViewModel], Never>) {
        
        self.layers = layers
        updates.assign(to: &$layers)
        updatesBinding = updates.drop(while: { $0.isEmpty == false })
            .map { _ in DelegateAction.dismiss }
            .subscribe(delegateActionSubject)
    }
    
    public var delegateAction: AnyPublisher<DelegateAction, Never> {
        
        delegateActionSubject.eraseToAnyPublisher()
    }
    
    public func playButtonDidTaped(for layerID: Layer.ID) {
        
        guard let layer = layers.first(where: { $0.id == layerID }) else {
            return
        }
        
        delegateActionSubject.send(.isPlayingDidChanged(layer.id, !layer.isPlaying))
    }
    
    public func muteButtonDidTapped(for layerID: Layer.ID) {
        
        guard let layer = layers.first(where: { $0.id == layerID }) else {
            return
        }
        
        delegateActionSubject.send(.isMutedDidChanged(layer.id, !layer.isMuted))
    }
    
    public func selectDidTapped(for layerID: Layer.ID) {
        
        delegateActionSubject.send(.selectLayer(layerID))
    }
    
    public func deleteButtonDidTapped(for layerID: Layer.ID) {
        
        delegateActionSubject.send(.deleteLayer(layerID))
    }
}

public extension LayersControlViewModel {
    
    enum DelegateAction: Equatable {
        
        case isPlayingDidChanged(Layer.ID, Bool)
        case isMutedDidChanged(Layer.ID, Bool)
        case deleteLayer(Layer.ID)
        case selectLayer(Layer.ID)
        case dismiss
    }
}
