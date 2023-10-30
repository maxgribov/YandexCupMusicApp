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
    
    public func retrieveSamplesIDs(for instrument: Instrument, complete: @escaping (Result<[SampleID], Swift.Error>) -> Void) {
        
        do {
            let path = try path()
            let fileNames = try fileManager.contentsOfDirectory(atPath: path)
                .filter { $0.hasPrefix(instrument.rawValue) }
            
            complete(.success(fileNames))
            
        } catch {
            
            complete(.failure(error))
        }
    }
    
    public enum Error: Swift.Error {
        
        case unableRetrieveResourcePathForBundle
    }
    
    private func path() throws -> String {
        
        guard let path = bundle.resourcePath else {
            throw Error.unableRetrieveResourcePathForBundle
        }
        
        return path
    }
}

public extension BundleSamplesLocalStore {
    
    static var moduleBundle: Bundle { Bundle.module }
}
