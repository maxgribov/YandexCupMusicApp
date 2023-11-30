//
//  FoundationRecordingSessionConfiguratorTests.swift
//  
//
//  Created by Max Gribov on 02.11.2023.
//

import XCTest
import AVFoundation
import Combine
import Processing

#if os(iOS)

final class FoundationRecordingSessionConfiguratorTests: XCTestCase {
    
    func test_isRecordingEnabled_receiveConfigureSessionAndRequestPermissionOnFirstAttempt() {
        
        let (sut, session) = makeSUT()
        
        _ = ValueSpy(sut.isRecordingEnabled())
        
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
    
    func test_isRecordingEnabled_deliversFalseOnSeccondAttemptWithPermissionsDeniedOnFirst() {
        
        let (sut, session) = makeSUT()
        
        expect(sut, result: false) {
            
            session.respondForRecordPermissionRequest(allowed: false)
        }
        
        expect(sut, result: false) {}
    }
    
    func test_isRecordingEnabled_deliversTrueOnSeccondAttemptWithPermissionsDeniedOnFirst() {
        
        let (sut, session) = makeSUT()
        
        expect(sut, result: true) {
            
            session.respondForRecordPermissionRequest(allowed: true)
        }
        
        expect(sut, result: true) {}
    }
    
    //MARK: - Helpers
    
    private func makeSUT(
        setCategoryError: Error? = nil,
        setActiveError: Error? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> (
        sut: FoundationRecordingSessionConfigurator<AVAudioSessionSpy>,
        session: AVAudioSessionSpy
    ) {
        
        let session = AVAudioSessionSpy()
        session.setCategoryErrorStub = setCategoryError
        session.setActiveErrorStub = setActiveError
        let sut = FoundationRecordingSessionConfigurator(session: session)
        
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
        
        func overrideOutputAudioPort(_ portOverride: AVAudioSession.PortOverride) throws {
            
            //TODO: Tests required
        }
    }
    
    private func expect(
        _ sut: FoundationRecordingSessionConfigurator<AVAudioSessionSpy>,
        result expectedResult: Bool,
        on action: () -> Void,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        
        let isRecordingEnabledSpy = ValueSpy(sut.isRecordingEnabled())
        
        action()
        
        XCTAssertEqual(isRecordingEnabledSpy.values, [expectedResult])
    }
    
    private func expect(
        _ sut: FoundationRecordingSessionConfigurator<AVAudioSessionSpy>,
        error expectedError: Error,
        on action: () -> Void,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        
        let isRecordingEnabledSpy = ValueSpy(sut.isRecordingEnabled())
        
        action()
        
        XCTAssertEqual(isRecordingEnabledSpy.events, [.failure(expectedError as NSError)], file: file, line: line)
    }
}

#endif
