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
    private let queue = DispatchConcurrentQueue(label: "BundleSamplesLocalStoreQueue")
    
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
    
    public func retrieveSample(for sampleID: SampleID, completion: @escaping (Result<Sample, Swift.Error>) -> Void) {
        
        do {
            
            let path = try path()
            let filePath = path + "/" + sampleID
            let url = URL(filePath: filePath)
            
            queue.async {
                
                guard let data = try? Data(contentsOf: url) else {
                    return completion(.failure(Error.retrieveSampleFileFailed))
                }
                
                completion(.success(Sample(name: sampleID, data: data)))
            }
            
        } catch {
            
            completion(.failure(error))
        }
    }
    
    public enum Error: Swift.Error {
        
        case unableRetrieveResourcePathForBundle
        case retrieveSampleFileFailed
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
