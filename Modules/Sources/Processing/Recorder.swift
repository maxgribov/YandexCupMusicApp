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
    func startRecording() throws -> AnyPublisher<Data, Error>
    func stopRecording()
}
