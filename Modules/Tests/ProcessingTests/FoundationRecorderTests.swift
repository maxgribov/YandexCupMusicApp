//
//  FoundationRecorderTests.swift
//  
//
//  Created by Max Gribov on 01.11.2023.
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

final class FoundationRecorder {
    
    private let session: AVAudioSessionProtocol
    private var permissionsState: RecordingPermissions
    private let recordingStatusSubject = CurrentValueSubject<RecordingStatus, Never>(.idle)
    
    init(session: AVAudioSessionProtocol) {
        
        self.session = session
        self.permissionsState = .required
    }
    
    func isRecording() -> AnyPublisher<Bool, Never> {
        
        recordingStatusSubject
            .map { status in
                
                switch status {
                case .inProgress: return true
                default: return false
                }
                
            }.eraseToAnyPublisher()
    }
    
    func startRecording() -> AnyPublisher<Data, Error> {
        
        switch permissionsState {
        case .required:
            return configureSessionAndRequestPermissions()
                .handleEvents(
                    receiveOutput: { self.permissionsState = $0 ? .allowed : .rejected }
                )
                .flatMap { result in
                    
                    switch result {
                    case true:
                        return self._startRecording()
                        
                    case false:
                        return self.recordingPermissionRejectError()
                    }
                    
                }.eraseToAnyPublisher()
            
        case .allowed:
            return _startRecording()
            
        case .rejected:
            return self.recordingPermissionRejectError()
        }
    }
    
    private func _startRecording() -> AnyPublisher<Data, Error> {
        
        // start recording here
        
        return self.recordingStatusSubject
            .tryMap { status in
                
                switch status {
                case let .complete(data): return data
                default:
                    throw NSError(domain: "", code: 0)
                }
                
            }.eraseToAnyPublisher()
    }
    
    private func recordingPermissionRejectError() -> AnyPublisher<Data, Error> {
        
        Fail<Data, Error>(error: FoundationRecorderError.recordingPermissionsNotGranted).eraseToAnyPublisher()
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
    
    enum RecordingStatus {
        
        case idle
        case inProgress(URL)
        case complete(Data)
        case failed
    }
}

enum FoundationRecorderError: Error {
    
    case recordingPermissionsNotGranted
}

final class FoundationRecorderTests: XCTestCase {
    
    var cancellables = Set<AnyCancellable>()
    
    override func setUp() async throws {
        try await super.setUp()
        
        cancellables = []
    }

    func test_init_recordingNothing() {
        
        let (sut, _) = makeSUT()
        let isRecordingSpy = ValueSpy(sut.isRecording())
        
        XCTAssertEqual(isRecordingSpy.values, [false])
    }
    
    func test_startRecording_setCategoryForSessionAndActiveAndRequestedPermissionsOnFirstAttempt() throws {
        
        let (sut, session) = makeSUT()
        
        _ = sut.startRecording()
        
        XCTAssertEqual(session.messages, [.setCategory(.playAndRecord, .default), .setActive(true), .requestPermission])
    }
    
    func test_startRecording_receiveRejectPermissionsErrorOnPermissionsRequestFailureOnFirstAttempt() {
        
        let (sut, session) = makeSUT()
        
        var receivedError: Error? = nil
        sut.startRecording()
            .sink(receiveCompletion: { completion in
                
                switch completion {
                case let .failure(error):
                    receivedError = error
                    
                case .finished:
                    break
                }
            }, receiveValue: { _ in })
            .store(in: &cancellables)
        
        session.respondForRecordPermissionRequest(allowed: false)
        
        XCTAssertEqual(receivedError as? FoundationRecorderError, .recordingPermissionsNotGranted)
    }
    
    //MARK: - Helpers
    
    private func makeSUT(
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> (
        sut: FoundationRecorder,
        session: AVAudioSessionSpy
    ) {
        
        let session = AVAudioSessionSpy()
        let sut = FoundationRecorder(session: session)
        
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
