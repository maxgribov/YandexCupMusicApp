//
//  LayerControl.swift
//
//
//  Created by Max Gribov on 29.11.2023.
//

import Foundation
import Domain

public extension Layer.Control {
    
    var rate: Float {
        
        Float(((2.0 - 0.5) * min(max(speed, 0), 1)) + 0.5)
    }
}
