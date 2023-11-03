//
//  AppModel.swift
//  YandexCupMusicApp
//
//  Created by Max Gribov on 04.11.2023.
//

import Foundation
import Combine
import Domain
import Processing
import Persistence

final class AppModel<S> where S: SamplesLocalStore {
    
    let producer: Producer
    let localStore: S
    
    init(producer: Producer, localStore: S) {
        
        self.producer = producer
        self.localStore = localStore
    }
    
    func activeLayer() -> AnyPublisher<Layer?, Never> {
        
        producer
            .$layers.zip(producer.$active)
            .map { layers, activeLayerID in
                
                guard let activeLayerID, let layer = layers.first(where: { $0.id == activeLayerID }) else {
                    return nil
                }
                
                return layer
                
            }.eraseToAnyPublisher()
    }
    
    func sampleIDs(for instrument: Instrument) -> AnyPublisher<[Sample.ID], Error> {
        
        Deferred {
            
            Future { [weak self] promise in
                
                self?.localStore.retrieveSamplesIDs(for: instrument, complete: promise)
            }
            
        }.eraseToAnyPublisher()
    }
    
    func loadSample(sampleID: Sample.ID) -> AnyPublisher<Sample, Error> {
        
        Deferred {
            
            Future { [weak self] promise in
                
                self?.localStore.retrieveSample(for: sampleID, completion: promise)
            }
            
        }.eraseToAnyPublisher()
    }
    
    func layers() -> AnyPublisher<(LayersUpdate), Never> {
        
        producer
            .$layers.combineLatest(producer.$active)
            .map { layers, active in LayersUpdate(layers: layers, active: active) }
            .removeDuplicates()
            .eraseToAnyPublisher()
    }
}
