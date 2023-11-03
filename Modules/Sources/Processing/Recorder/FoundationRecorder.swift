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
    private let makeRecorder: (URL, [String : Any]) throws -> R
    private let fileManager: FileManager
    
    public init(
        makeRecorder: @escaping (URL, [String : Any]) throws -> R,
        fileManager: FileManager = .default
    ) {
        
        self.makeRecorder = makeRecorder
        self.fileManager = fileManager
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
    
    public func stopRecording() {
        
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
    
    public func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        
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
