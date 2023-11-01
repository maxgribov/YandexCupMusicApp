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

protocol AVAudioRecorderProtocol: AnyObject {
    
    init(
        url: URL,
        settings: [String : Any]
    ) throws
    
}

extension AVAudioRecorder: AVAudioRecorderProtocol {}

final class FoundationRecorder {
    
    private let session: AVAudioSessionProtocol
    private var permissionsState: RecordingPermissions
    private let recordingStatusSubject = CurrentValueSubject<RecordingStatus, Never>(.idle)
    private let makeRecorder: (URL, [String : Any]) throws -> AVAudioRecorderProtocol
    
    init(session: AVAudioSessionProtocol, makeRecorder: @escaping (URL, [String : Any]) throws -> AVAudioRecorderProtocol) {
        
        self.session = session
        self.permissionsState = .required
        self.makeRecorder = makeRecorder
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
                    receiveOutput: { [weak self] result in
                        
                        self?.permissionsState = result ? .allowed : .rejected
                    }
                )
                .flatMap { [weak self] result in
                    
                    guard let self else {
                        return Fail<Data, Error>(error: FoundationRecorderError.recorderInstanceDeinitedDuringRecording).eraseToAnyPublisher()
                    }
                    
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
        
        recordingStatusSubject.send(.inProgress(URL(string: "http://www.some-url.com")!))
        
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
    case recorderInstanceDeinitedDuringRecording
}

final class FoundationRecorderTests: XCTestCase {
    
    private var recorder: AVAudioRecorderSpy? = nil
    private var cancellables = Set<AnyCancellable>()
    
    override func setUp() async throws {
        try await super.setUp()
        
        cancellables = []
        recorder = nil
    }

    func test_init_recordingNothing() {
        
        let (sut, _) = makeSUT()
        let isRecordingSpy = ValueSpy(sut.isRecording())
        
        XCTAssertEqual(isRecordingSpy.values, [false])
    }
    
    func test_startRecording_setCategoryForSessionAndActiveAndRequestedPermissionsOnFirstAttempt() throws {
        
        let (sut, session) = makeSUT()
        
        sut.startRecording()
            .sink(receiveCompletion: { _ in}, receiveValue: { _ in  })
            .store(in: &cancellables)
        
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
    
    func test_startRecording_startsRecordingOnPermissionsRequestSussessOnFirstAttempt() {
        
        let (sut, session) = makeSUT()
        let isRecordingSpy = ValueSpy(sut.isRecording())
        
        sut.startRecording()
            .sink(receiveCompletion: { _ in}, receiveValue: { _ in  })
            .store(in: &cancellables)
        
        session.respondForRecordPermissionRequest(allowed: true)
        
        XCTAssertEqual(isRecordingSpy.values, [false, true])
    }
    
    func test_startRecording_deliversErrorOnRecorderInitFailureOnFirstAttempt() {
        
        let session = AVAudioSessionSpy()
        let sut = FoundationRecorder(session: session) { url, settings in
            
             try AlwaysFailsAVAudioRecorderSpy(url: url, settings: settings)
        }
        
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
        
        session.respondForRecordPermissionRequest(allowed: true)
        
        XCTAssertNotNil(receivedError)
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
        let sut = FoundationRecorder(session: session) { url, settings in
            
            let recorder = try AVAudioRecorderSpy(url: url, settings: settings)
            self.recorder = recorder
            
            return recorder
        }
        
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
    
    private class AVAudioRecorderSpy: AVAudioRecorderProtocol {
        
        required init(url: URL, settings: [String : Any]) throws {
            
        }
    }
    
    private class AlwaysFailsAVAudioRecorderSpy: AVAudioRecorderProtocol {
        
        required init(url: URL, settings: [String : Any]) throws {
            
            throw NSError(domain: "", code: 0)
        }
    }
}

// samples settings
// ["AVChannelLayoutKey": <02006500 00000000 00000000>, "AVSampleRateKey": 44100, "AVNumberOfChannelsKey": 2, "AVFormatIDKey": 1633772320]

#endif
