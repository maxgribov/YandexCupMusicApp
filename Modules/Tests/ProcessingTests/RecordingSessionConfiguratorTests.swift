//
//  RecordingSessionConfiguratorTests.swift
//  
//
//  Created by Max Gribov on 02.11.2023.
//

import XCTest
import AVFoundation
import Combine

#if os(iOS)
protocol AVAudioSessionProtocol: AnyObject {
    
    func setCategory(
        _ category: AVAudioSession.Category,
        mode: AVAudioSession.Mode,
        options: AVAudioSession.CategoryOptions
    ) throws
    
    func setActive(
        _ active: Bool,
        options: AVAudioSession.SetActiveOptions
    ) throws
    
    func requestRecordPermission(
        _ response: @escaping (
            Bool
        ) -> Void
    )
}

extension AVAudioSession: AVAudioSessionProtocol {}

final class RecordingSessionConfigurator {
    
    private let session: AVAudioSessionProtocol
    private var permissionsState: RecordingPermissions
    
    init(session: AVAudioSessionProtocol) {
        
        self.session = session
        self.permissionsState = .required
    }
        
    func isRecordingEnabled() -> AnyPublisher<Bool, Error> {
    
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
                    return Just(true).setFailureType(to: Error.self).eraseToAnyPublisher()
                    
                case .rejected:
                    return Just(false).setFailureType(to: Error.self).eraseToAnyPublisher()
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

final class RecordingSessionConfiguratorTests: XCTestCase {
    
    private var cancellables = Set<AnyCancellable>()
    
    override func setUp() async throws {
        try await super.setUp()
        
        cancellables = []
    }
    
    func test_isRecordingEnabled_receiveConfigureSessionAndRequestPermissionOnFirstAttempt() {
        
        let (sut, session) = makeSUT()
        
        sut.isRecordingEnabled()
            .sink(receiveCompletion: { _ in  }, receiveValue: { _ in })
            .store(in: &cancellables)
        
        XCTAssertEqual(session.messages, [.setCategory(.playAndRecord, .default), .setActive(true), .requestPermission])
    }

    func test_isRecordingEnabled_receiveFalseWithPermissionsDeniedOnFirstAttempt() {
        
        let (sut, session) = makeSUT()
        
        var receivedResult: Bool? = nil
        sut.isRecordingEnabled()
            .sink(receiveCompletion: { _ in  },
                  receiveValue: { result in
                
                receivedResult = result
            })
            .store(in: &cancellables)
        
        session.respondForRecordPermissionRequest(allowed: false)
        
        XCTAssertEqual(receivedResult, false)
    }
    
    func test_isRecordingEnabled_receiveTrueWithPermissionsGrantedOnFirstAttempt() {
        
        let (sut, session) = makeSUT()
        
        var receivedResult: Bool? = nil
        sut.isRecordingEnabled()
            .sink(receiveCompletion: { _ in  },
                  receiveValue: { result in
                
                receivedResult = result
            })
            .store(in: &cancellables)
        
        session.respondForRecordPermissionRequest(allowed: true)
        
        XCTAssertEqual(receivedResult, true)
    }
    
    //MARK: - Helpers
    
    private func makeSUT(
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> (
        sut: RecordingSessionConfigurator,
        session: AVAudioSessionSpy
    ) {
        
        let session = AVAudioSessionSpy()
        let sut = RecordingSessionConfigurator(session: session)
        
        trackForMemoryLeaks(session, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        
        return (sut, session)
    }
    
    private class AVAudioSessionSpy: AVAudioSessionProtocol {
        
        private(set) var messages = [Message]()
        private var responses = [(Bool) -> Void]()
        
        enum Message: Equatable {
            
            case setCategory(AVAudioSession.Category, AVAudioSession.Mode)
            case setActive(Bool)
            case requestPermission
        }
        
        func setCategory(_ category: AVAudioSession.Category, mode: AVAudioSession.Mode, options: AVAudioSession.CategoryOptions) throws {
            
            messages.append(.setCategory(category, mode))
        }
        
        func setActive(_ active: Bool, options: AVAudioSession.SetActiveOptions) throws {
            
            messages.append(.setActive(active))
        }
        
        func requestRecordPermission(_ response: @escaping (Bool) -> Void) {
            
            messages.append(.requestPermission)
            responses.append(response)
        }
        
        func respondForRecordPermissionRequest(allowed: Bool, at index: Int = 0) {
            
            responses[index](allowed)
        }
    }
}

#endif
