//
//  AudioEngineComposerTests.swift
//  
//
//  Created by Max Gribov on 28.11.2023.
//

import XCTest
import AVFoundation
import Combine
import Processing

final class AudioEngineComposer {
     
    private let engine: AVAudioEngine
    private let makeNode: (Track) -> AudioEnginePlayerNodeProtocol?
    
    init(engine: AVAudioEngine, makeNode: @escaping (Track) -> AudioEnginePlayerNodeProtocol?) {
        
        self.engine = engine
        self.makeNode = makeNode
    }
    
    func compose(tracks: [Track]) -> AnyPublisher<URL, Error> {
        
        _ = tracks.map { makeNode($0) }
        
        return Fail(error: NSError(domain: "", code: 0)).eraseToAnyPublisher()
    }
}

struct Track {
    
    let id: UUID
    let data: Data
    let volume: Float
    let rate: Float
}

final class AudioEngineComposerTests: XCTestCase {

    func test_init_doesNotMessagesEngine() {
        
        let engine = AVAudioEngineSpy()
        let _ = AudioEngineComposer(engine: engine, makeNode: { track in
            AudioEnginePlayerNodeSpy(with: track.data)
        })
        
        XCTAssertEqual(engine.messages, [])
    }
    
    func test_composeTracks_createsPlayersForTracks() {
        
        let engine = AVAudioEngineSpy()
        var resultNodes = [AudioEnginePlayerNodeSpy?]()
        let sut = AudioEngineComposer(engine: engine, makeNode: { track in
            let node = AudioEnginePlayerNodeSpy(with: track.data)
            resultNodes.append(node)
            return node
        })
        
        _ = sut.compose(tracks: [.init(id: anyLayerID(), data: anyData(), volume: anyVolume(), rate: anyRate()),
                                 .init(id: anyLayerID(), data: anyData(), volume: anyVolume(), rate: anyRate())])
        
        XCTAssertEqual(resultNodes.compactMap{ $0 }.count, 2)
    }
    
    //MARK: - Helpers
    
    private func anyVolume() -> Float {
        
        Float.random(in: 0...1)
    }
    
    private func anyRate() -> Float {
        
        Float.random(in: 0...1)
    }
}
