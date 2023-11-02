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
    
    func test_isRecordingEnabled_deliversErrorWithSetCategoryFailureOnFirstAttempt() {
        
        let error = anyNSError()
        let (sut, _) = makeSUT(setCategoryError: error)
        
        expect(sut, error: error) {}
    }
    
    func test_isRecordingEnabled_deliversErrorWithSetActiveFailureOnFirstAttempt() {
        
        let error = anyNSError()
        let (sut, _) = makeSUT(setActiveError: error)
        
        expect(sut, error: error) {}
    }

    func test_isRecordingEnabled_deliversFalseWithPermissionsDeniedOnFirstAttempt() {
        
        let (sut, session) = makeSUT()
        
        expect(sut, result: false) {
            
            session.respondForRecordPermissionRequest(allowed: false)
        }
    }
    
    func test_isRecordingEnabled_deliversTrueWithPermissionsGrantedOnFirstAttempt() {
        
        let (sut, session) = makeSUT()
        
        expect(sut, result: true) {
            
            session.respondForRecordPermissionRequest(allowed: true)
        }
    }
    
    //MARK: - Helpers
    
    private func makeSUT(
        setCategoryError: Error? = nil,
        setActiveError: Error? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> (
        sut: RecordingSessionConfigurator,
        session: AVAudioSessionSpy
    ) {
        
        let session = AVAudioSessionSpy()
        session.setCategoryErrorStub = setCategoryError
        session.setActiveErrorStub = setActiveError
        let sut = RecordingSessionConfigurator(session: session)
        
        trackForMemoryLeaks(session, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        
        return (sut, session)
    }
    
    private class AVAudioSessionSpy: AVAudioSessionProtocol {
        
        private(set) var messages = [Message]()
        private var responses = [(Bool) -> Void]()
        
        var setCategoryErrorStub: Error?
        var setActiveErrorStub: Error?
        
        enum Message: Equatable {
            
            case setCategory(AVAudioSession.Category, AVAudioSession.Mode)
            case setActive(Bool)
            case requestPermission
        }
        
        func setCategory(_ category: AVAudioSession.Category, mode: AVAudioSession.Mode, options: AVAudioSession.CategoryOptions) throws {
            
            messages.append(.setCategory(category, mode))
            
            if let setCategoryErrorStub {
                
                throw setCategoryErrorStub
            }
        }
        
        func setActive(_ active: Bool, options: AVAudioSession.SetActiveOptions) throws {
            
            messages.append(.setActive(active))
            
            if let setActiveErrorStub {
                
                throw setActiveErrorStub
            }
        }
        
        func requestRecordPermission(_ response: @escaping (Bool) -> Void) {
            
            messages.append(.requestPermission)
            responses.append(response)
        }
        
        func respondForRecordPermissionRequest(allowed: Bool, at index: Int = 0) {
            
            responses[index](allowed)
        }
    }
    
    private func expect(
        _ sut: RecordingSessionConfigurator,
        result expectedResult: Bool,
        on action: () -> Void,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        
        let resultExp = expectation(description: "Wait for result")
        let completionExp = expectation(description: "Wait for completion")
        sut.isRecordingEnabled()
            .sink(receiveCompletion: { completion in
                
                switch completion {
                case let .failure(error):
                    XCTFail("Expected result: \(expectedResult), got \(error) instead", file: file, line: line)
                    
                case .finished:
                    break
                }
                
                completionExp.fulfill()
                
            }, receiveValue: { receivedResult in
                
                XCTAssertEqual(receivedResult, expectedResult, file: file, line: line)
                resultExp.fulfill()
            })
            .store(in: &cancellables)
        
        action()
        
        wait(for: [resultExp, completionExp], timeout: 1.0)
    }
    
    private func expect(
        _ sut: RecordingSessionConfigurator,
        error expectedError: Error,
        on action: () -> Void,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        
        let completionExp = expectation(description: "Wait for completion")
        sut.isRecordingEnabled()
            .sink(receiveCompletion: { completion in
                
                switch completion {
                case let .failure(error):
                    XCTAssertEqual(error as NSError, expectedError as NSError, file: file, line: line)
                    
                case .finished:
                    break
                }
                
                completionExp.fulfill()
                
            }, receiveValue: { receivedResult in
                
                XCTFail("Expect error: \(expectedError), got result: \(receivedResult) instead", file: file, line: line)
            })
            .store(in: &cancellables)
        
        action()
        
        wait(for: [completionExp], timeout: 1.0)
    }
    
    private func anyNSError() -> NSError {
        
        NSError(domain: "", code: 0)
    }
}

#endif
