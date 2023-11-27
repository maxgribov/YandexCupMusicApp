//
//  SampleSelectorViewModel.swift
//  
//
//  Created by Max Gribov on 31.10.2023.
//

import Foundation
import Combine
import Domain

public final class SampleSelectorViewModel {
    
    public let instrument: Instrument
    public let items: [SampleItemViewModel]
    
    private let delegateActionSubject = PassthroughSubject<DelegateAction, Never>()
    
    public init(instrument: Instrument, items: [SampleItemViewModel]) {
        
        self.instrument = instrument
        self.items = items
    }
    
    public var delegateAction: AnyPublisher<DelegateAction, Never> {
        
        delegateActionSubject.eraseToAnyPublisher()
    }
    
    public func itemDidSelected(for itemID: SampleItemViewModel.ID) {
        
        guard let item = items.first(where: { $0.id == itemID }) else { return }
        
        delegateActionSubject.send(.sampleDidSelected(item.id, instrument))
    }
}

public extension SampleSelectorViewModel {
    
    enum DelegateAction: Equatable {
        
        case sampleDidSelected(Sample.ID, Instrument)
    }
}
