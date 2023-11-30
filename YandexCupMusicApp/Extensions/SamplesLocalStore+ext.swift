//
//  SamplesLocalStore+ext.swift
//  YandexCupMusicApp
//
//  Created by Max Gribov on 04.11.2023.
//

import Foundation
import Combine
import Domain
import Persistence
import Presentation

extension SamplesLocalStore {
    
    func sampleIDs(for instrument: Instrument) -> AnyPublisher<[Sample.ID], Error> {
        
        Deferred {
            
            Future { promise in
                
                retrieveSamplesIDs(for: instrument, complete: promise)
            }
            
        }.eraseToAnyPublisher()
    }
    
    func sampleIDsMain(for instrument: Instrument) -> AnyPublisher<[Sample.ID], Error> {
        
        sampleIDs(for: instrument).receive(on: DispatchQueue.main).eraseToAnyPublisher()
    }
    
    func loadSample(sampleID: Sample.ID) -> AnyPublisher<Sample, Error> {
        
        Deferred {
            
            Future { promise in
                
                retrieveSample(for: sampleID, completion: promise)
            }
            
        }.eraseToAnyPublisher()
    }
    
    func loadSampleMain(sampleID: Sample.ID) -> AnyPublisher<Sample, Error> {
        
        loadSample(sampleID: sampleID).receive(on: DispatchQueue.main).eraseToAnyPublisher()
    }
    
    func defaultSample(for instrument: Instrument) -> AnyPublisher<Sample, Error> {
        
        sampleIDs(for: instrument)
            .compactMap { sampleIDs in return sampleIDs.first }
            .flatMap { sampleID in return loadSample(sampleID: sampleID) }
            .eraseToAnyPublisher()
    }
    
    func makeSampleSelector(instrument: Instrument) -> AnyPublisher<SampleSelectorViewModel, Error> {
        
        sampleIDsMain(for: instrument).makeSampleItemViewModels().map { SampleSelectorViewModel(instrument: instrument, items: $0) }.eraseToAnyPublisher()
    }
}
