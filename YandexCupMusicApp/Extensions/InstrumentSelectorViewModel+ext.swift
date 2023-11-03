//
//  InstrumentSelectorViewModel+ext.swift
//  YandexCupMusicApp
//
//  Created by Max Gribov on 03.11.2023.
//

import Foundation
import Presentation

extension InstrumentSelectorViewModel {
    
    static let initial = InstrumentSelectorViewModel(buttons: [.init(instrument: .guitar),
                                                               .init(instrument: .drums),
                                                               .init(instrument: .brass)])
}
