//
//  AVAudioEngineSpy.swift
//
//
//  Created by Max Gribov on 28.11.2023.
//

import AVFoundation

class AVAudioEngineSpy: AVAudioEngine {
    
    private(set) var messages = [Message]()
    
    enum Message: Equatable {
        
        case prepare
        case start
        case attach(AVAudioNode)
        case connect(AVAudioNode, AVAudioNode)
        case disconnect(AVAudioNode)
        case detach(AVAudioNode)
        case stop
    }
    
    override var isRunning: Bool { _isRunning }
    private var _isRunning: Bool = false
    
    var startErrorStub: Error?
    var mainMixerNodeStub: AVAudioMixerNode?
    
    override func prepare() {
        
        messages.append(.prepare)
    }
    
    override func start() throws {
         
        messages.append(.start)
        
        if let startErrorStub {
            throw startErrorStub
        }
    }
    
    func simulateEngineStarted() {
        
        _isRunning = true
    }
    
    override func attach(_ node: AVAudioNode) {
        
        messages.append(.attach(node))
    }
    
    override func connect(_ node1: AVAudioNode, to node2: AVAudioNode, format: AVAudioFormat?) {
        
        messages.append(.connect(node1, node2))
    }
    
    override func disconnectNodeInput(_ node: AVAudioNode) {
        
        messages.append(.disconnect(node))
    }
    
    override func detach(_ node: AVAudioNode) {
        
        messages.append(.detach(node))
    }
    
    override func stop() {
        
        messages.append(.stop)
    }
    
    override var mainMixerNode: AVAudioMixerNode {
        
        if let stub = mainMixerNodeStub {
            
            return stub
            
        } else {
            
            return super.mainMixerNode
        }
    }
}
