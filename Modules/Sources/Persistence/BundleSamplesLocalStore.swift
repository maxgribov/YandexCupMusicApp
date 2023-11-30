//
//  BundleSamplesLocalStore.swift
//  
//
//  Created by Max Gribov on 30.10.2023.
//

import Foundation
import Domain

public final class BundleSamplesLocalStore: SamplesLocalStore {
    
    private let bundle: Bundle
    private let fileManager = FileManager.default
    private let queue = DispatchQueue(label: "BundleSamplesLocalStoreQueue", qos: .userInitiated, attributes: [.concurrent])
    private let mapper: (URL) -> Data?
    
    public init(
        bundle: Bundle? = nil,
        mapper: @escaping (URL) -> Data? = BundleSamplesLocalStore.basicMapper(url:)
    ) {
        
        self.bundle = bundle ?? Self.moduleBundle
        self.mapper = mapper
    }
        
    public func retrieveSamplesIDs(for instrument: Instrument, complete: @escaping (Result<[Sample.ID], Swift.Error>) -> Void) {
        
        do {
            let path = try path()
            let fileNames = try fileManager.contentsOfDirectory(atPath: path)
                .filter { $0.hasPrefix(instrument.rawValue) }
            
            complete(.success(fileNames))
            
        } catch {
            
            complete(.failure(error))
        }
    }
    
    public func retrieveSample(for sampleID: Sample.ID, completion: @escaping (Result<Sample, Swift.Error>) -> Void) {
        
        do {
            
            let path = try path()
            
            queue.async {
                
                let filePath = path + "/" + sampleID
                let url = URL(filePath: filePath)
                
                guard let data = self.mapper(url) else {
                    return completion(.failure(Error.retrieveSampleFileFailed))
                }
                
                completion(.success(Sample(id: sampleID, data: data)))
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
    
    static func basicMapper(url: URL) -> Data? {
        
        try? Data(contentsOf: url)
    }
}
