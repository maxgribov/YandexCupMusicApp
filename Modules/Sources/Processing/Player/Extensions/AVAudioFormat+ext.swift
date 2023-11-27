//
//  AVAudioFormat+ext.swift
//
//
//  Created by Max Gribov on 27.11.2023.
//

import AVFoundation

public extension AVAudioFormat {
    
    static let shared = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: 44100, channels: 2, interleaved: false)!
}
