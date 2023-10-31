//
//  InstrumentButtonViewModel.swift
//
//
//  Created by Max Gribov on 31.10.2023.
//

import Foundation
import Samples

public struct InstrumentButtonViewModel: Identifiable, Equatable {

    public var id: String { instrument.rawValue }
    public let instrument: Instrument
    
    public init(instrument: Instrument) {
        self.instrument = instrument
    }
}
