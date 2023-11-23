//
//  ValueSpy.swift
//
//
//  Created by Max Gribov on 31.10.2023.
//

import Foundation
import Combine

final class ValueSpy<Value> {

    private (set) var events = [Event]()
    private var cancellables: AnyCancellable?
    
    init<P>(_ publisher: P) where P: Publisher, P.Output == Value {
        
        self.cancellables = publisher.sink(
            receiveCompletion: { [weak self] completion in
                
                switch completion {
                case .finished:
                    self?.events.append(.finished)
                    
                case let .failure(error):
                    self?.events.append(.failure(error as NSError))
                }
            },
            receiveValue: { [weak self] value in
                
                self?.events.append(.value(value))
            }
        )
    }
    
    var values: [Value] { events.compactMap(\.value) }
    
    enum Event {
        
        case failure(NSError)
        case finished
        case value(Value)
        
        var value: Value? {

            guard case let .value(value) = self
            else { return nil }
            
            return value
        }
    }
}

extension ValueSpy.Event: Equatable where Value: Equatable {}

