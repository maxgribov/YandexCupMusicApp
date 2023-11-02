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

protocol AVAudioRecorderProtocol: AnyObject {
    
    init(
        url: URL,
        settings: [String : Any]
    ) throws
    
    var delegate: AVAudioRecorderDelegate? { get set }
    
    @discardableResult
    func record() -> Bool
    func stop()
}

extension AVAudioRecorder: AVAudioRecorderProtocol {}

final class FoundationRecorder: NSObject {
    
    private let recordingStatusSubject = CurrentValueSubject<RecordingStatus, Never>(.idle)
    private let makeRecorder: (URL, [String : Any]) throws -> AVAudioRecorderProtocol
    private let fileManager: FileManager
    
    init(
        makeRecorder: @escaping (
            URL,
            [String : Any]
        ) throws -> AVAudioRecorderProtocol,
        fileManager: FileManager = .default
    ) {
        
        self.makeRecorder = makeRecorder
        self.fileManager = fileManager
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
        
        do {
            
            let recorder = try makeRecorder(makeRecordingURL(), makeRecordingSettings())
            recorder.delegate = self
            recorder.record()
            recordingStatusSubject.send(.inProgress(recorder))
            
            return self.recordingStatusSubject
                .dropFirst()
                .tryMap { status in
                    
                    switch status {
                    case let .complete(data): return data
                    default: throw FoundationRecorderError.recordFailedError
                    }
                }
                .eraseToAnyPublisher()
            
        } catch {
            
            return Fail<Data, Error>(error: FoundationRecorderError.recorderInitFailure).eraseToAnyPublisher()
        }
    }
    
    func stopRecording() {
        
        guard case let .inProgress(recorder) = recordingStatusSubject.value else {
            return
        }
        
        recorder.stop()
    }
    
    private func makeRecordingURL() -> URL {
        
        getDocumentsDirectory().appendingPathComponent("recording.m4a")
    }
    
    private func makeRecordingSettings() -> [String: Any] {
        
        [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 12000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
    }
    
    private func getDocumentsDirectory() -> URL {
        
        fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    enum RecordingStatus {
        
        case idle
        case inProgress(AVAudioRecorderProtocol)
        case complete(Data)
        case failed
    }
}

extension FoundationRecorder: AVAudioRecorderDelegate {
    
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        
        switch flag {
        case true:
            do {
                
                let data = try Data(contentsOf: recorder.url)
                recordingStatusSubject.send(.complete(data))
                
            } catch {
                
                recordingStatusSubject.send(.failed)
            }

        case false:
            recordingStatusSubject.send(.failed)
        }
    }
}

enum FoundationRecorderError: Error {
    
    case recorderInitFailure
    case recordFailedError
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
        let isRecordingSpy = ValueSpy(sut.isRecording())
        
        sut.startRecording()
            .sink(receiveCompletion: { _ in}, receiveValue: { _ in  })
            .store(in: &cancellables)
        
        XCTAssertEqual(isRecordingSpy.values, [false, true])
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
        let isRecordingSpy = ValueSpy(sut.isRecording())
        
        sut.startRecording()
            .sink(receiveCompletion: { _ in}, receiveValue: { _ in  })
            .store(in: &cancellables)
 
        sut.stopRecording()
        recorder?.delegate?.audioRecorderDidFinishRecording?(try makeAVAudioRecorderStub(url: anyURL()), successfully: false)
        
        XCTAssertEqual(isRecordingSpy.values, [false, true, false])
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
        let isRecordingSpy = ValueSpy(sut.isRecording())
        
        sut.startRecording()
            .sink(receiveCompletion: { _ in}, receiveValue: { _ in  })
            .store(in: &cancellables)
 
        sut.stopRecording()
        recorder?.delegate?.audioRecorderDidFinishRecording?(try makeAVAudioRecorderStub(url: anyURL()), successfully: true)
        
        XCTAssertEqual(isRecordingSpy.values, [false, true, false])
    }
    
    func test_stopRecording_deliversDataOnSuccessRecordingAndSuccessDataFetching() throws {
        
        let sut = makeSUT()
        
        var receivedData: Data? = nil
        sut.startRecording()
            .sink(receiveCompletion: { _ in }, receiveValue: { result in  receivedData = result })
            .store(in: &cancellables)
        
        sut.stopRecording()
        let (expectedData, url) = try makeAudioDataStub()
        recorder?.delegate?.audioRecorderDidFinishRecording?(try makeAVAudioRecorderStub(url: url), successfully: true)
        
        XCTAssertEqual(receivedData, expectedData)
    }
    
    func test_stopRecording_stopsIsRecordingOnSuccessRecordingAndSuccessDataFetching() throws {
        
        let sut = makeSUT()
        let isRecordingSpy = ValueSpy(sut.isRecording())
        
        sut.startRecording()
            .sink(receiveCompletion: { _ in}, receiveValue: { _ in  })
            .store(in: &cancellables)
 
        sut.stopRecording()
        let (_, url) = try makeAudioDataStub()
        recorder?.delegate?.audioRecorderDidFinishRecording?(try makeAVAudioRecorderStub(url: url), successfully: true)
        
        XCTAssertEqual(isRecordingSpy.values, [false, true, false])
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

#endif
