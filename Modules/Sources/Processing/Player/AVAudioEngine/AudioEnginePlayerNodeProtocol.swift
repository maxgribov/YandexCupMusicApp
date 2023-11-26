//
//  File.swift
//  
//
//  Created by Max Gribov on 26.11.2023.
//

import AVFoundation
import Domain

public protocol AudioEnginePlayerNodeProtocol {
    
    associatedtype Engine: AVAudioEngineProtocol
    
    var offset: AVAudioTime { get }
    var duration: TimeInterval { get }
    
    init?(with data: Data)
    func connect(to engine: Engine)
    func disconnect(from engine: Engine)
    func play()
    func stop()
    func set(volume: Float)
    func set(rate: Float)
    func set(offset: AVAudioTime)
}
