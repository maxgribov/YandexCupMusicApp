//
//  BundleSamplesLocalStore.swift
//  
//
//  Created by Max Gribov on 30.10.2023.
//

import Foundation

public final class BundleSamplesLocalStore {
    
    private let bundle: Bundle
    private let fileManager = FileManager.default
    
    public init(bundle: Bundle? = nil) {
        
        self.bundle = bundle ?? Self.moduleBundle
    }
    
    public func retrieveSamples(for instrument: Instrument, completion: @escaping (SamplesLocalStore.Result) -> Void) {
        
        guard let path = bundle.resourcePath else {
            return completion(.failure(Error.unableRetrieveResourcePathForBundle))
        }
    }
    
    public enum Error: Swift.Error {
        
        case unableRetrieveResourcePathForBundle
    }
}

public extension BundleSamplesLocalStore {
    
    static var moduleBundle: Bundle { Bundle.module }
}
