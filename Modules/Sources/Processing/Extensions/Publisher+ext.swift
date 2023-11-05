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
            
            if let duration {
                
                return Just(Date() .timeIntervalSinceReferenceDate)
                    .merge(with: Timer
                        .publish(every: duration, on: .main, in: .common)
                        .autoconnect()
                        .map { $0.timeIntervalSinceReferenceDate })
                    .map { startTime in
                        
                        return Timer
                            .publish(every: 0.1, on: .main, in: .common)
                            .autoconnect()
                            .map { $0.timeIntervalSinceReferenceDate }
                            .map { currentTime in
                                
                                duration > 0 ? (currentTime - startTime) / duration : 0
                                
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
