//
//  Instrument+ext.swift
//
//
//  Created by Max Gribov on 02.11.2023.
//

import SwiftUI
import Domain

extension Instrument {
    
    var buttonIcon: Image {
        
        switch self {
        case .guitar: return Image(.iconGuitar)
        case .drums: return Image(.iconDrums)
        case .brass: return Image(.iconBrass)
        }
    }
}
