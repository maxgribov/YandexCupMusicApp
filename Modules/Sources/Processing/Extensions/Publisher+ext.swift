//
//  Publisher+ext.swift
//  
//
//  Created by Max Gribov on 05.11.2023.
//

import Foundation
import Combine

extension Publisher where Output == TimeInterval?, Failure == Never {
    
    func progressEvents() -> AnyPublisher<Double, Never> {
        
        map { duration in
            
            if let duration, duration > 0 {
                
                return Timer
                    .publish(every: duration, on: .main, in: .common)
                    .autoconnect()
                    .map { $0.timeIntervalSinceReferenceDate }
                    .merge(with: Just(Date().timeIntervalSinceReferenceDate))
                    .map { startTime in
                        
                        return Timer
                            .publish(every: 0.1, on: .main, in: .common)
                            .autoconnect()
                            .map { $0.timeIntervalSinceReferenceDate }
                            .map { currentTime in
                                
                                (currentTime - startTime) / duration
                                
                            }.eraseToAnyPublisher()
                    }
                    .switchToLatest()
                    .eraseToAnyPublisher()
                
            } else {
                
                return Just(Double(0)).eraseToAnyPublisher()
            }
        }
        .switchToLatest()
        .eraseToAnyPublisher()
    }
}
