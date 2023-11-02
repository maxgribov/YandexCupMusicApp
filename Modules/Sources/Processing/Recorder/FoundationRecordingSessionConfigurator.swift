//
//  FoundationRecordingSessionConfigurator.swift
//
//
//  Created by Max Gribov on 02.11.2023.
//

import AVFoundation
import Combine

#if os(iOS)

public final class FoundationRecordingSessionConfigurator<S> where S: AVAudioSessionProtocol {
    
    private let session: S
    private var permissionsState: RecordingPermissions
    
    public init(session: S) {
        
        self.session = session
        self.permissionsState = .required
    }
        
    public func isRecordingEnabled() -> AnyPublisher<Bool, Error> {
    
        Just(permissionsState)
            .setFailureType(to: Error.self)
            .flatMap { [unowned self] state in
                
                switch state {
                case .required:
                    return self.configureSessionAndRequestPermissions()
                        .handleEvents(
                            receiveOutput: { [weak self] result in
                                
                                self?.permissionsState = result ? .allowed : .rejected
                            }
                        ).eraseToAnyPublisher()
                    
                case .allowed:
                    return Just(true)
                        .setFailureType(to: Error.self)
                        .eraseToAnyPublisher()
                    
                case .rejected:
                    return Just(false)
                        .setFailureType(to: Error.self)
                        .eraseToAnyPublisher()
                }
                
            }.eraseToAnyPublisher()
    }
    
    private func configureSessionAndRequestPermissions() -> AnyPublisher<Bool, Error> {
        
        Future { [weak self] promise in
            
            do {
                
                try self?.session.setCategory(.playAndRecord, mode: .default, options: [])
                try self?.session.setActive(true, options: [])
                self?.session.requestRecordPermission { result in
                    
                    promise(.success(result))
                }
                
            } catch {
                
                promise(.failure(error))
            }
            
        }.eraseToAnyPublisher()
    }
    
    enum RecordingPermissions {
        
        case required
        case allowed
        case rejected
    }
}

#endif
