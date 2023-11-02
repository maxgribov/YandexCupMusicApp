//
//  InstrumentSelectorViewModel.swift
//  
//
//  Created by Max Gribov on 31.10.2023.
//

import Foundation
import Combine
import Domain

public final class InstrumentSelectorViewModel {
    
    public let buttons: [InstrumentButtonViewModel]
    private let delegateActionSubject = PassthroughSubject<DelegateAction, Never>()
    
    public init(buttons: [InstrumentButtonViewModel]) {
        
        self.buttons = buttons
    }
    
    public var delegateAction: AnyPublisher<DelegateAction, Never> {
        
        delegateActionSubject.eraseToAnyPublisher()
    }
    
    public func buttonDidTapped(for buttonID: InstrumentButtonViewModel.ID) {
        
        guard let buttonViewModel = buttons.first(where: { $0.id == buttonID }) else {
            return
        }
        
        delegateActionSubject.send(.instrumentDidSelected(buttonViewModel.instrument))
    }
}

public extension InstrumentSelectorViewModel {
    
    enum DelegateAction: Equatable {
        
        case instrumentDidSelected(Instrument)
    }
}
