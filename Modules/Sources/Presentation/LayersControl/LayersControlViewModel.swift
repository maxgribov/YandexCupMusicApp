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
    
    private var bindings = Set<AnyCancellable>()
    private var layersDelegateBindings = Set<AnyCancellable>()
    
    public init(initial layers: [LayerViewModel], updates: AnyPublisher<[LayerViewModel], Never>) {
        
        self.layers = layers
        updates.assign(to: &$layers)
        
        bind()
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
    
    private func bind() {
        
        $layers
            .sink { [unowned self] layers in
                
                layersDelegateBindings = []
                layers.forEach(bind(layer:))
                
            }.store(in: &bindings)
    }
    
    private func bind(layer: LayerViewModel) {
        
        layer.delegateAction
            .sink { [weak self] delegateAction in
                
                guard let self else { return }
                
                switch delegateAction {
                case let .isPlayingDidChanged(isPlaying):
                    delegateActionSubject.send(.isPlayingDidChanged(layer.id, isPlaying))
                    
                case let .isMutedDidChanged(isMuted):
                    delegateActionSubject.send(.isMutedDidChanged(layer.id, isMuted))
                    
                case .deleteLayer:
                    delegateActionSubject.send(.deleteLayer(layer.id))
                    
                case .selectLayer:
                    delegateActionSubject.send(.selectLayer(layer.id))
                }
                
            }.store(in: &layersDelegateBindings)
    }
}

public extension LayersControlViewModel {
    
    enum DelegateAction: Equatable {
        
        case isPlayingDidChanged(Layer.ID, Bool)
        case isMutedDidChanged(Layer.ID, Bool)
        case deleteLayer(Layer.ID)
        case selectLayer(Layer.ID)
    }
}
