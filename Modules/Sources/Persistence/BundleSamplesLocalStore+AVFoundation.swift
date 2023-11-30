//
//  BundleSamplesLocalStore+AVFoundation.swift
//  
//
//  Created by Max Gribov on 25.11.2023.
//

import AVFoundation

public extension BundleSamplesLocalStore {
    
    static func bufferMapper(url: URL) -> Data? {
        
        guard let file = try? AVAudioFile(forReading: url),
              let buffer = try? AVAudioPCMBuffer.makeAndReadBuffer(from: file) 
        else {
            
            return nil
        }
        
        return Data(buffer: buffer)
    }
}

private extension AVAudioPCMBuffer {
    
    struct UnableCreateAudioPCMBufferFromAudioFileError: Error {}
    
    static func makeAndReadBuffer(from file: AVAudioFile) throws -> AVAudioPCMBuffer {
        
        guard let buffer = AVAudioPCMBuffer(
            pcmFormat: file.processingFormat,
            frameCapacity: UInt32(file.length)) else {
            
            throw UnableCreateAudioPCMBufferFromAudioFileError()
        }
        
        try file.read(into: buffer)
        
        return buffer
    }
}

private extension Data {
    
    init?(buffer: AVAudioPCMBuffer) {
        
        let audioBuffer = buffer.audioBufferList.pointee.mBuffers
        guard let bytes = audioBuffer.mData else {
            return nil
        }
        
        self.init(bytes: bytes, count: Int(audioBuffer.mDataByteSize))
    }
}

