//
//  Recorder.swift
//  
//
//  Created by Max Gribov on 31.10.2023.
//

import Foundation
import Combine

public protocol Recorder {
    
    func isRecording() -> AnyPublisher<Bool, Never>
    func startRecording() -> AnyPublisher<Data, Error>
    func stopRecording()
}
