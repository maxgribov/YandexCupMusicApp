//
//  Instrument.swift
//
//
//  Created by Max Gribov on 30.10.2023.
//

import Foundation

public enum Instrument: String, CaseIterable {
    
    case guitar
    case drums
    case brass
}

public extension Instrument {
    
    //TODO: localisation required
    var name: String {
        
        switch self {
        case .guitar: return "Гитара"
        case .drums: return "Ударные"
        case .brass: return "Духовые"
        }
    }
}
