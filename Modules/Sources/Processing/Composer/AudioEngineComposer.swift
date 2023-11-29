//
//  AudioEngineComposer.swift
//  
//
//  Created by Max Gribov on 29.11.2023.
//

import AVFoundation
import Combine

public final class AudioEngineComposer<Node>: Composer where Node: AudioEnginePlayerNodeProtocol {
     
    private let engine: AVAudioEngine
    private let makeNode: (Track) -> Node?
    private let makeRecordingFile: (AVAudioFormat) throws -> AVAudioFile
    private var outputRecordingFile: AVAudioFile?
    private var nodes = [Node]()
    
    private var stateSubject = CurrentValueSubject<State, Never>(.idle)
    
    private enum State {
        
        case idle
        case compositing
        case complete(URL)
        case failure(Error)
    }
    
    public init(engine: AVAudioEngine, makeNode: @escaping (Track) -> Node?, makeRecordingFile: @escaping (AVAudioFormat) throws -> AVAudioFile) {
        
        self.engine = engine
        self.makeNode = makeNode
        self.makeRecordingFile = makeRecordingFile
    }
    
    public func isCompositing() -> AnyPublisher<Bool, Never> {
        
        stateSubject
            .map { state in
            
                switch state {
                case .compositing: return true
                default: return false
                }
                
            }
            .removeDuplicates()
            .eraseToAnyPublisher()
    }
    
    public func compose(tracks: [Track]) -> AnyPublisher<URL, ComposerError> {
        
        stateSubject.send(.idle)
        
        nodes = tracks.map { track in
        
            let node = makeNode(track)
            node?.set(volume: track.volume)
            node?.set(rate: track.rate)
            
            return node
            
        }.compactMap { $0 }
        
        guard nodes.isEmpty == false else {
            
            stateSubject.send(.failure(ComposerError.nodesMappingFailure))
            return Fail(error: .nodesMappingFailure).eraseToAnyPublisher()
        }
        
        nodes.forEach { node in
            
            node.connect(to: engine)
        }
        
        do {
            
            let outputFormat = engine.mainMixerNode.outputFormat(forBus: 0)
            outputRecordingFile = try makeRecordingFile(outputFormat)
            engine.mainMixerNode.removeTap(onBus: 0)
            engine.mainMixerNode.installTap(onBus: 0, bufferSize: 1023, format: outputFormat) { [weak self] buffer, _ in
                
                do {
                    
                    try self?.outputRecordingFile?.write(from: buffer)
                    
                } catch {
                    
                    self?.stateSubject.send(.failure(error))
                }
            }
            
            try engine.start()
            nodes.forEach { node in
                
                node.schedule(offset: nil)
                node.play()
            }
            
            stateSubject.send(.compositing)
            
            return stateSubject
                .drop(while: { state in
                    switch state {
                    case .idle, .compositing:
                        return true
                        
                    default:
                        return false
                    }
                })
                .tryMap { state in
                    
                    switch state {
                    case let .complete(url): return url
                    default: throw ComposerError.compositingFailure
                    }
                }
                .mapError{ $0 as! ComposerError }
                .eraseToAnyPublisher()
            
        } catch {
            
            stateSubject.send(.failure(error))
            return Fail(error: .engineStartFailure).eraseToAnyPublisher()
        }
    }
    
    public func stop() {
        
        engine.stop()
        nodes.forEach { node in
            
            node.stop()
            node.disconnect(from: engine)
        }
        nodes = []
        
        if let url = outputRecordingFile?.url {
            
            stateSubject.send(.complete(url))
            
        } else {
            
            stateSubject.send(.failure(ComposerError.compositingFailure))
        }
    }
}
