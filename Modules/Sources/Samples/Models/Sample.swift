//
//  Sample.swift
//
//
//  Created by Max Gribov on 30.10.2023.
//

import Foundation

public struct Sample: Equatable {

    public typealias ID = String
    public let id: ID
    public let data: Data
    
    public init(id: String, data: Data) {
        self.id = id
        self.data = data
    }
}
