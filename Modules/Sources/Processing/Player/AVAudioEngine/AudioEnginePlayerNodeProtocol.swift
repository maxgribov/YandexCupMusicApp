//
//  File.swift
//  
//
//  Created by Max Gribov on 26.11.2023.
//

import AVFoundation
import Domain

public protocol AudioEnginePlayerNodeProtocol {
    
    var offset: AVAudioTime { get }
    var duration: TimeInterval { get }
    
    init?(with data: Data)
    func connect(to engine: AVAudioEngine)
    func disconnect(from engine: AVAudioEngine)
    func schedule(offset: AVAudioTime?)
    func play()
    func stop()
    func set(volume: Float)
    func set(rate: Float)
}
