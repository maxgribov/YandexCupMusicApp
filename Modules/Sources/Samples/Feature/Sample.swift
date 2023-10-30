//
//  Sample.swift
//
//
//  Created by Max Gribov on 30.10.2023.
//

import Foundation

public struct Sample: Equatable {

    public let name: String
    public let data: Data
    
    public init(name: String, data: Data) {
        self.name = name
        self.data = data
    }
}
