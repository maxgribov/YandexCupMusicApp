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
}
