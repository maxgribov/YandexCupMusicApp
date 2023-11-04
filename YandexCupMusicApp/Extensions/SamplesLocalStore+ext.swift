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

extension SamplesLocalStore {
    
    func sampleIDs(for instrument: Instrument) -> AnyPublisher<[Sample.ID], Error> {
        
        Deferred {
            
            Future { [weak self] promise in
                
                self?.retrieveSamplesIDs(for: instrument, complete: promise)
            }
            
        }.eraseToAnyPublisher()
    }
    
    func loadSample(sampleID: Sample.ID) -> AnyPublisher<Sample, Error> {
        
        Deferred {
            
            Future { [weak self] promise in
                
                self?.retrieveSample(for: sampleID, completion: promise)
            }
            
        }.eraseToAnyPublisher()
    }
    
    func defaultSample(for instrument: Instrument) -> AnyPublisher<Sample, Error> {
        
        sampleIDs(for: instrument)
            .compactMap { sampleIDs in return sampleIDs.first }
            .flatMap { [unowned self] sampleID in return self.loadSample(sampleID: sampleID) }
            .eraseToAnyPublisher()
    }
}
