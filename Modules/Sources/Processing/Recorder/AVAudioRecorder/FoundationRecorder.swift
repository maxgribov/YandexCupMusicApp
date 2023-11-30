//
//  FoundationRecorder.swift
//  
//
//  Created by Max Gribov on 02.11.2023.
//

import AVFoundation
import Combine

public final class FoundationRecorder<R>: NSObject, AVAudioRecorderDelegate, Recorder where R: AVAudioRecorderProtocol {
    
    private let recordingStatusSubject = CurrentValueSubject<RecordingStatus, Never>(.idle)
    private let makeRecorder: (URL, AVAudioFormat) throws -> R
    private let fileManager: FileManager
    private let mapper: (URL) -> Data?
    
    public init(
        makeRecorder: @escaping (URL, AVAudioFormat) throws -> R,
        fileManager: FileManager = .default,
        mapper: @escaping (URL) -> Data? = FoundationRecorder.basicMapper(url:)
    ) {
        
        self.makeRecorder = makeRecorder
        self.fileManager = fileManager
        self.mapper = mapper
    }
    
    public func isRecording() -> AnyPublisher<Bool, Never> {
        
        recordingStatusSubject
            .map { status in
                
                switch status {
                case .inProgress: return true
                default: return false
                }
                
            }.eraseToAnyPublisher()
    }
    
    public func startRecording() -> AnyPublisher<Data, Error> {
        
        do {
            
            let recorder = try makeRecorder(makeRecordingURL(), .shared)
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
    
    public func stopRecording() {
        
        guard case let .inProgress(recorder) = recordingStatusSubject.value else {
            return
        }
        
        recorder.stop()
    }
    
    private func makeRecordingURL() -> URL {
        
        getDocumentsDirectory().appendingPathComponent("recording.m4a")
    }
    
    private func getDocumentsDirectory() -> URL {
        
        fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    public func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        
        switch flag {
        case true:
            if let data = mapper(recorder.url) {
                
                recordingStatusSubject.send(.complete(data))
                
            } else {
                
                recordingStatusSubject.send(.failed)
            }

        case false:
            recordingStatusSubject.send(.failed)
        }
    }

    enum RecordingStatus {
        
        case idle
        case inProgress(AVAudioRecorderProtocol)
        case complete(Data)
        case failed
    }
}

public enum FoundationRecorderError: Error {
    
    case recorderInitFailure
    case recordFailedError
}

public extension FoundationRecorder {
    
    static func basicMapper(url: URL) -> Data? {
        
        try? Data(contentsOf: url)
    }
}
