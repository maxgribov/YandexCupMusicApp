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



final class AudioEngineComposerTests: XCTestCase {
    
    var resultNodes = [AudioEnginePlayerNodeSpy?]()
    
    override func setUp() async throws {
        try await super.setUp()
        
        resultNodes = []
    }

    func test_init_doesNotMessagesEngine() {
        
        let (_, engine) = makeSUT()
        
        XCTAssertEqual(engine.messages, [])
    }
    
    func test_composeTracks_createsPlayersForTracks() {
        
        let (sut, _) = makeSUT()
        
        _ = sut.compose(tracks: [.init(id: anyLayerID(), data: anyData(), volume: anyVolume(), rate: anyRate()),
                                 .init(id: anyLayerID(), data: anyData(), volume: anyVolume(), rate: anyRate())])
        
        XCTAssertEqual(resultNodes.compactMap{ $0 }.count, 2)
    }
    
    //MARK: - Helpers
    
    private func makeSUT(
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> (
        sut: AudioEngineComposer,
        engine: AVAudioEngineSpy
    ) {
        
        let engine = AVAudioEngineSpy()
        let sut = AudioEngineComposer(engine: engine, makeNode: { [weak self] track in
            let node = AudioEnginePlayerNodeSpy(with: track.data)
            self?.resultNodes.append(node)
            return node
        })
        
        trackForMemoryLeaks(sut, file: file, line: line)
        trackForMemoryLeaks(engine, file: file, line: line)
        
        return (sut, engine)
    }
    
    private func anyVolume() -> Float {
        
        Float.random(in: 0...1)
    }
    
    private func anyRate() -> Float {
        
        Float.random(in: 0...1)
    }
}
