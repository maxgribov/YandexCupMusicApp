//
//  SampleItemViewModel.swift
//  
//
//  Created by Max Gribov on 31.10.2023.
//

import Foundation
import Domain

public struct SampleItemViewModel: Identifiable, Equatable {
    
    public let id: Sample.ID
    public let name: String
    
    public init(id: Sample.ID, name: String) {
        
        self.id = id
        self.name = name
    }
}
