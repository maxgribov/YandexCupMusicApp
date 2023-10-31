//
//  Sample.swift
//
//
//  Created by Max Gribov on 30.10.2023.
//

import Foundation

public typealias SampleID = String

public struct Sample: Equatable {

    public let id: SampleID
    public let data: Data
    
    public init(id: String, data: Data) {
        self.id = id
        self.data = data
    }
}
