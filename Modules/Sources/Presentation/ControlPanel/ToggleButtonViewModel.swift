//
//  ToggleButtonViewModel.swift
//  
//
//  Created by Max Gribov on 03.11.2023.
//

import Foundation

public final class ToggleButtonViewModel: ObservableObject, Enablable {
    
    public let type: Kind
    @Published public var isActive: Bool
    @Published public var isEnabled: Bool
    
    public init(type: Kind, isActive: Bool, isEnabled: Bool) {
        
        self.type = type
        self.isActive = isActive
        self.isEnabled = isEnabled
    }
    
    public enum Kind {
        
        case record
        case compose
        case play
    }
}
