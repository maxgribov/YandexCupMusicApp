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
        
        $layers.zip($active)
            .map { layers, activeLayerID in
                
                guard let activeLayerID, let layer = layers.first(where: { $0.id == activeLayerID }) else {
                    return nil
                }
                
                return layer
                
            }.eraseToAnyPublisher()
    }
    
    func layers() -> AnyPublisher<LayersUpdate, Never> {
        
        $layers.combineLatest($active)
            .map { layers, active in LayersUpdate(layers: layers, active: active) }
            .removeDuplicates()
            .eraseToAnyPublisher()
    }
}