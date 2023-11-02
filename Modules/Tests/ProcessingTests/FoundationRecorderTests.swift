//
//  FoundationRecorderTests.swift
//  
//
//  Created by Max Gribov on 01.11.2023.
//

import XCTest
import Combine
import AVFoundation
import Processing

final class FoundationRecorderTests: XCTestCase {
    
    private var recorder: AVAudioRecorderSpy? = nil
    private var cancellables = Set<AnyCancellable>()
    
    override func setUp() async throws {
        try await super.setUp()
        
        cancellables = []
        recorder = nil
    }

    func test_init_recordingNothing() {
        
        let sut = makeSUT()
        let isRecordingSpy = ValueSpy(sut.isRecording())
        
        XCTAssertEqual(isRecordingSpy.values, [false])
    }
    
    func test_startRecording_deliversErrorOnRecorderInitFailure() throws {
        
        let sut = FoundationRecorder() { url, settings in
            try AlwaysFailsAVAudioRecorderSpy(url: url, settings: settings)
        }
        
        expect(sut, error: FoundationRecorderError.recorderInitFailure, on: {})
    }
    
    func test_startRecording_invokesRecordMethodOnRecorder() {
        
        let sut = makeSUT()
        
        sut.startRecording()
            .sink(receiveCompletion: { _ in}, receiveValue: { _ in  })
            .store(in: &cancellables)
        
        XCTAssertEqual(recorder?.messages, [.initialisation, .record])
    }

    func test_startRecording_startsRecording() {
        
        let sut = makeSUT()
        
        expect(sut, isRecordingValuesAfterStartRecordingInvocation: [false, true], on: {})
    }
    
    func test_stopRecording_doesNothingIfRecordingDidNotStartedPreviously() {
        
        let sut = makeSUT()
        let isRecordingSpy = ValueSpy(sut.isRecording())
        
        sut.stopRecording()
        
        XCTAssertEqual(isRecordingSpy.values, [false])
    }
    
    func test_stopRecording_invokesStopMethodOnRecorder() {
        
        let sut = makeSUT()
        
        sut.startRecording()
            .sink(receiveCompletion: { _ in}, receiveValue: { _ in  })
            .store(in: &cancellables)
        
        sut.stopRecording()
        
        XCTAssertEqual(recorder?.messages, [.initialisation, .record, .stop])
    }
    
    func test_stopRecording_deliversErrorOnRecorderFinishWithNoSuccess() throws {
        
        let sut = makeSUT()
        
        let recorderStub = try makeAVAudioRecorderStub(url: anyURL())
        expect(sut, error: FoundationRecorderError.recordFailedError, on: {
            
            sut.stopRecording()
            recorder?.delegate?.audioRecorderDidFinishRecording?(recorderStub, successfully: false)
        })
    }
    
    func test_stopRecording_stopsIsRecordingStateOnRecorderFinishWithNoSuccess() throws {
        
        let sut = makeSUT()
        
        let recorderStub = try makeAVAudioRecorderStub(url: anyURL())
        expect(sut, isRecordingValuesAfterStartRecordingInvocation: [false, true, false], on: {
            
            sut.stopRecording()
            recorder?.delegate?.audioRecorderDidFinishRecording?(recorderStub, successfully: false)
        })
    }
    
    func test_stopRecording_deliversErrorOnRecorderFinishWithSuccessButDataFetchingFailed() throws {
        
        let sut = makeSUT()
        
        let recorderStub = try makeAVAudioRecorderStub(url: anyURL())
        expect(sut, error: FoundationRecorderError.recordFailedError, on: {
            
            sut.stopRecording()
            recorder?.delegate?.audioRecorderDidFinishRecording?(recorderStub, successfully: true)
        })
    }
    
    func test_stopRecording_stopsIsRecordingOnRecorderFinishWithSuccessButDataFetchingFailed() throws {
        
        let sut = makeSUT()
        
        let recorderStub = try makeAVAudioRecorderStub(url: anyURL())
        expect(sut, isRecordingValuesAfterStartRecordingInvocation: [false, true, false], on: {
            
            sut.stopRecording()
            recorder?.delegate?.audioRecorderDidFinishRecording?(recorderStub, successfully: true)
        })
    }
    
    func test_stopRecording_deliversDataOnSuccessRecordingAndSuccessDataFetching() throws {
        
        let sut = makeSUT()
        
        let (expectedData, url) = try makeAudioDataStub()
        let recorderStub = try makeAVAudioRecorderStub(url: url)
        expect(sut, result: expectedData) {
            
            sut.stopRecording()
            recorder?.delegate?.audioRecorderDidFinishRecording?(recorderStub, successfully: true)
        }
    }
    
    func test_stopRecording_stopsIsRecordingOnSuccessRecordingAndSuccessDataFetching() throws {
        
        let sut = makeSUT()
        
        let (_, url) = try makeAudioDataStub()
        let recorderStub = try makeAVAudioRecorderStub(url: url)
        expect(sut, isRecordingValuesAfterStartRecordingInvocation: [false, true, false], on: {
            
            sut.stopRecording()
            recorder?.delegate?.audioRecorderDidFinishRecording?(recorderStub, successfully: true)
        })
    }

    //MARK: - Helpers
    
    private func makeSUT(
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> FoundationRecorder {
        
        let sut = FoundationRecorder { url, settings in
            
            let recorder = try AVAudioRecorderSpy(url: url, settings: settings)
            self.recorder = recorder
            
            return recorder
        }
        
        trackForMemoryLeaks(sut, file: file, line: line)
        
        return sut
    }
    
    private class AVAudioRecorderSpy: AVAudioRecorderProtocol {
        
        private(set) var messages = [Message]()
        
        enum Message: Equatable {
            
            case initialisation
            case record
            case stop
        }
        
        weak var delegate: AVAudioRecorderDelegate?
        
        required init(url: URL, settings: [String : Any]) throws {
            
            messages.append(.initialisation)
        }
        
        func record() -> Bool {
            
            messages.append(.record)
            return true
        }
        
        func stop() {
            
            messages.append(.stop)
        }
    }
    
    private class AlwaysFailsAVAudioRecorderSpy: AVAudioRecorderProtocol {
        
        weak var delegate: AVAudioRecorderDelegate?
        
        required init(url: URL, settings: [String : Any]) throws {
            
            throw NSError(domain: "", code: 0)
        }
        
        func record() -> Bool { return false }
        func stop() {}
    }
    
    private func makeAVAudioRecorderStub(url: URL) throws -> AVAudioRecorder {
        
        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 12000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        return try AVAudioRecorder(url: url, settings: settings)
    }
    
    private func expect(
        _ sut: FoundationRecorder,
        error expectedError: Error,
        on action: () -> Void,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        
        let exp = expectation(description: "Wait for completion")
        sut.startRecording()
            .sink(receiveCompletion: { completion in
                
                switch completion {
                case let .failure(receivedError):
                    XCTAssertEqual(receivedError as NSError, expectedError as NSError, "Expected \(expectedError), got: \(receivedError) instead", file: file, line: line)
                    
                case .finished:
                    XCTFail("Expected error: \(expectedError), got finished instead", file: file, line: line)
                }
                
                exp.fulfill()
                
            }, receiveValue: { result in
                
                XCTFail("Expected error: \(expectedError), got result: \(result) instead", file: file, line: line)
            })
            .store(in: &cancellables)
        
        action()
        
        wait(for: [exp], timeout: 1.0)
    }
    
    private func expect(
        _ sut: FoundationRecorder,
        result expectedResult: Data,
        on action: () -> Void,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        
        let expResult = expectation(description: "Wait for result")
        sut.startRecording()
            .sink(receiveCompletion: { completion in
                
                switch completion {
                case let .failure(receivedError):
                    XCTFail("Expected error: \(expectedResult), got error: \(receivedError) instead", file: file, line: line)
                    
                case .finished:
                    break
                }
                
            }, receiveValue: { receivedResult in
                
                XCTAssertEqual(receivedResult, expectedResult, file: file, line: line)
                expResult.fulfill()
            })
            .store(in: &cancellables)
        
        action()
        
        wait(for: [expResult], timeout: 1.0)
    }
    
    private func expect(
        _ sut: FoundationRecorder,
        isRecordingValuesAfterStartRecordingInvocation expectedValues: [Bool],
        on action: () -> Void,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        
        let isRecordingSpy = ValueSpy(sut.isRecording())
        
        sut.startRecording()
            .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
            .store(in: &cancellables)
        
        action()
        
        XCTAssertEqual(isRecordingSpy.values, expectedValues, file: file, line: line)
    }
    
    private func makeAudioDataStub() throws -> (data: Data, url: URL) {
        
        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("recording.m4a")
        let data = Data("recording stub data".utf8)
        try data.write(to: url)
        
        return (data, url)
    }
    
    private func anyURL() -> URL {
    
        URL(string: "www.any-url.com")!
    }
    
    private func anyNSError() -> NSError {
        
        NSError(domain: "", code: 0)
    }
}
