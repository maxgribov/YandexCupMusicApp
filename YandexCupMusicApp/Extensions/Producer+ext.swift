//
//  Producer+ext.swift
//  YandexCupMusicApp
//
//  Created by Max Gribov on 04.11.2023.
//

import Foundation
import Combine
import Domain
import Processing
import Presentation

extension Producer {
    
    func activeLayer() -> AnyPublisher<Layer?, Never> {
        
        $active
            .map {[unowned self] activeLayerID in
                
                guard let activeLayerID, let layer = self.layers.first(where: { $0.id == activeLayerID }) else {
                    return nil
                }
                
                return layer
                
            }.eraseToAnyPublisher()
    }
    
    func activeLayerMain() -> AnyPublisher<Layer?, Never> {
        
        activeLayer().receive(on: DispatchQueue.main).eraseToAnyPublisher()
    }
    
    func layers() -> AnyPublisher<LayersUpdate, Never> {
        
        $layers.combineLatest($active)
            .map { layers, active in LayersUpdate(layers: layers, active: active) }
            .removeDuplicates()
            .eraseToAnyPublisher()
    }
    
    func layersMain() -> AnyPublisher<LayersUpdate, Never> {
        
        layers().receive(on: DispatchQueue.main).eraseToAnyPublisher()
    }
    
    func layersButtonNameUpdates() -> AnyPublisher<String?, Never> {
        
        activeLayerMain().map { $0?.name }.eraseToAnyPublisher()
    }
    
    func composeButtonStatusUpdates() -> AnyPublisher<Bool, Never> {
        
        isCompositing()
    }
    
    func playButtonStatusUpdates() -> AnyPublisher<Bool, Never> {
        
        layersMain().isPlayingAll()
    }
    
    func activeLayerControlUpdates() -> AnyPublisher<Layer.Control?, Never> {
        
        activeLayerMain().control()
    }
    
    func layersViewModels() -> [LayerViewModel] {
        
        layers.map {
            
            LayerViewModel(
                id: $0.id,
                name: $0.name,
                isPlaying: $0.isPlaying,
                isMuted: $0.isMuted,
                isActive: $0.id == active
            )
        }
    }
    
    func layersViewModelsUpdates() -> AnyPublisher<[LayerViewModel], Never> {
        
        layersMain().makeLayerViewModels()
    }
    
    func sheetUpdates() -> AnyPublisher<MainViewModel.Sheet?, Never> {
        
        delegateAction
            .map { action in
                
                switch action {
                case let .compositingReady(url): return url
                default: return nil
                }
                
            }.mapToSheet()
            .eraseToAnyPublisher()
    }
}
