//
//  LayersButtonViewModel.swift
//  
//
//  Created by Max Gribov on 03.11.2023.
//

import Foundation

public final class LayersButtonViewModel: ObservableObject, Enablable {
    
    @Published public var name: String
    @Published public var isActive: Bool
    @Published public var isEnabled: Bool
    
    public init(name: String, isActive: Bool, isEnabled: Bool) {
        
        self.name = name
        self.isActive = isActive
        self.isEnabled = isEnabled
    }
}

public extension LayersButtonViewModel {
    
    static let initial = LayersButtonViewModel(name: "Слои", isActive: false, isEnabled: true)
}
