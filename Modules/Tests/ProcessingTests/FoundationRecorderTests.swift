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
}

extension AVAudioSession: AVAudioSessionProtocol {}

final class FoundationRecorder {
    
    private let isRecordingSubject = CurrentValueSubject<Bool, Never>(false)
    private let session: AVAudioSessionProtocol
    private var permissionsState: Permissions
    
    init(session: AVAudioSessionProtocol) {
        
        self.session = session
        self.permissionsState = .required
    }
    
    func isRecording() -> AnyPublisher<Bool, Never> {
        
        isRecordingSubject.eraseToAnyPublisher()
    }
    
    func startRecording() -> AnyPublisher<Data, Error> {
        
        switch permissionsState {
        case .required:
            return configureSessionAndRequestPermissions()
                .handleEvents(receiveOutput: { self.permissionsState = $0 ? .allowed : .rejected })
                .flatMap { result in
                    
                    return Future<Data, Error> { promise in
                        
                        promise(.success(Data()))
                    }
                    
                }.eraseToAnyPublisher()
            
        case .allowed:
            return Future<Data, Error> { promise in
                
                promise(.success(Data()))
                
            }.eraseToAnyPublisher()
            
        case .rejected:
            return Fail<Data, Error>(error: NSError(domain: "", code: 0)).eraseToAnyPublisher()
        }
    }
    
    private func configureSessionAndRequestPermissions() -> AnyPublisher<Bool, Error> {
        
        Future { [weak self] promise in
            
            do {
                
                try self?.session.setCategory(.playAndRecord, mode: .default, options: [])
                promise(.success(true))
                
            } catch {
                
                promise(.failure(error))
            }
            
        }.eraseToAnyPublisher()
    }
    
    enum Permissions {
        
        case required
        case allowed
        case rejected
    }
}


final class FoundationRecorderTests: XCTestCase {

    func test_init_recordingNothing() {
        
        let (sut, _) = makeSUT()
        let isRecordingSpy = ValueSpy(sut.isRecording())
        
        XCTAssertEqual(isRecordingSpy.values, [false])
    }
    
    func test_startRecording_setCategoryForSessionOnFirstAttempt() throws {
        
        let (sut, session) = makeSUT()
        
        _ = sut.startRecording()
        
        XCTAssertEqual(session.messages, [.setCategory(.playAndRecord, .default)])
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
        
        enum Message: Equatable {
            
            case setCategory(AVAudioSession.Category, AVAudioSession.Mode)
        }
        
        func setCategory(_ category: AVAudioSession.Category, mode: AVAudioSession.Mode, options: AVAudioSession.CategoryOptions = []) throws {
            
            messages.append(.setCategory(category, mode))
        }
    }
}

#endif
