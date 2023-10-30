//
//  SamplesLocalStore.swift
//
//
//  Created by Max Gribov on 30.10.2023.
//

import Foundation

public protocol SamplesLocalStore {
    
    typealias Result = Swift.Result<[Sample], Error>
    
    func retrieveSamples(for instrument: Instrument, completion: @escaping (Result) -> Void)
}
