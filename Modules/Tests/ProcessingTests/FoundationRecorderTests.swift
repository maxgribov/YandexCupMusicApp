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
    
}

extension AVAudioRecorder: AVAudioRecorderProtocol {}

final class FoundationRecorder {
    
    private let recordingStatusSubject = CurrentValueSubject<RecordingStatus, Never>(.idle)
    private let makeRecorder: (URL, [String : Any]) throws -> AVAudioRecorderProtocol
    private let fileManager: FileManager
    
    init(makeRecorder: @escaping (URL, [String : Any]) throws -> AVAudioRecorderProtocol, fileManager: FileManager = .default) {
        
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
            recordingStatusSubject.send(.inProgress(recorder))
            
            return self.recordingStatusSubject
                .tryMap { status in
                    
                    switch status {
                    case let .complete(data): return data
                    default:
                        throw NSError(domain: "", code: 0)
                    }
                }
                .eraseToAnyPublisher()
            
        } catch {
            
            return Fail<Data, Error>(error: NSError(domain: "", code: 0)).eraseToAnyPublisher()
        }
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
    
    func test_startRecording_deliversErrorOnRecorderInitFailure() {
        
        let sut = FoundationRecorder() { url, settings in
            
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
        
        XCTAssertNotNil(receivedError)
    }

    func test_startRecording_startsRecording() {
        
        let sut = makeSUT()
        let isRecordingSpy = ValueSpy(sut.isRecording())
        
        sut.startRecording()
            .sink(receiveCompletion: { _ in}, receiveValue: { _ in  })
            .store(in: &cancellables)
        
        XCTAssertEqual(isRecordingSpy.values, [false, true])
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
