//
//  SamplesLoader.swift
//
//
//  Created by Max Gribov on 30.10.2023.
//

import Foundation

public final class SamplesLoader<S> where S: SamplesLocalStore {
    
    private let store: S
    
    public init(store: S) {
        
        self.store = store
    }
    
    public func load(for instrument: Instrument, completion: @escaping (Result<[Sample], Error>) -> Void) {
        
        store.retrieveSamples(for: instrument) { [weak self] result in
        
            guard self != nil else { return }
            
            completion(result)
        }
    }
}
