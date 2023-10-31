//
//  SampleSelectorViewModel.swift
//  
//
//  Created by Max Gribov on 31.10.2023.
//

import Foundation
import Samples
import Combine

public final class SampleSelectorViewModel {
    
    public let buttons: [InstrumentButtonViewModel]
    public let delegateActionSubject = PassthroughSubject<DelegateAction, Never>()
    
    public init(buttons: [InstrumentButtonViewModel]) {
        
        self.buttons = buttons
    }
    
    public func buttonDidTapped(for buttonID: InstrumentButtonViewModel.ID) {
        
        guard let buttonViewModel = buttons.first(where: { $0.id == buttonID }) else {
            return
        }
        
        delegateActionSubject.send(.instrumentDidSelected(buttonViewModel.instrument))
    }
}

public extension SampleSelectorViewModel {
    
    enum DelegateAction: Equatable {
        
        case instrumentDidSelected(Instrument)
    }
}
