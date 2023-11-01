//
//  SamplesLocalStore.swift
//
//
//  Created by Max Gribov on 30.10.2023.
//

import Foundation
import Domain

public protocol SamplesLocalStore {
    
    func retrieveSamplesIDs(for instrument: Instrument, complete: @escaping (Result<[Sample.ID], Swift.Error>) -> Void)
    func retrieveSample(for sampleID: Sample.ID, completion: @escaping (Result<Sample, Swift.Error>) -> Void)
}
