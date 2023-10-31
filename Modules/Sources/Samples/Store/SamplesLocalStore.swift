//
//  SamplesLocalStore.swift
//
//
//  Created by Max Gribov on 30.10.2023.
//

import Foundation

public protocol SamplesLocalStore {
    
    func retrieveSamplesIDs(for instrument: Instrument, complete: @escaping (Result<[SampleID], Swift.Error>) -> Void)
    func retrieveSample(for sampleID: SampleID, completion: @escaping (Result<Sample, Swift.Error>) -> Void)
}
