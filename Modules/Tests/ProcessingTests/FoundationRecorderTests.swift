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
protocol AVAudioSessionProtocol {
    
    func setCategory(
        _ category: AVAudioSession.Category,
        mode: AVAudioSession.Mode,
        options: AVAudioSession.CategoryOptions
    ) throws
}

extension AVAudioSession: AVAudioSessionProtocol {}

final class FoundationRecorder {
    
    private let isRecordingSubject = CurrentValueSubject<Bool, Never>(false)
    
    func isRecording() -> AnyPublisher<Bool, Never> {
        
        isRecordingSubject.eraseToAnyPublisher()
    }
}

final class FoundationRecorderTests: XCTestCase {

    func test_init_recordingNothing() {
        
        let sut = FoundationRecorder()
        let isRecordingSpy = ValueSpy(sut.isRecording())
        
        XCTAssertEqual(isRecordingSpy.values, [false])
    }

}

#endif
