//
//  File.swift
//  
//
//  Created by Max Gribov on 28.11.2023.
//

import AVFoundation
import Processing

class AudioEnginePlayerNodeSpy: AudioEnginePlayerNodeProtocol {
    
    private(set) var messages = [Message]()
    
    enum Message: Equatable {
        
        case initWithData(Data)
        case connectToEngine
        case play
        case setVolume(Float)
        case setRate(Float)
        case schedule(AVAudioTime?)
        case stop
        case disconnectFromEngine
    }
    
    var offsetStub: AVAudioTime?
    var offset: AVAudioTime { offsetStub ?? .init() }
    static let durationStub: TimeInterval = 4.0
    var duration: TimeInterval { Self.durationStub }
    
    required init?(with data: Data) {
        
        messages.append(.initWithData(data))
    }
    
    func connect(to engine: AVAudioEngine) {
        
        messages.append(.connectToEngine)
    }
    
    func disconnect(from engine: AVAudioEngine) {
        
        messages.append(.disconnectFromEngine)
    }
    
    func play() {
         
        messages.append(.play)
    }
    
    func stop() {
        
        messages.append(.stop)
    }
    
    func set(volume: Float) {
        
        messages.append(.setVolume(volume))
    }
    
    func set(rate: Float) {
            
        messages.append(.setRate(rate))
    }
    
    func schedule(offset: AVAudioTime?) {
        
        messages.append(.schedule(offset))
    }
}
