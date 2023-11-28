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

final class AudioEngineComposer<Node> where Node: AudioEnginePlayerNodeProtocol {
     
    private let engine: AVAudioEngine
    private let makeNode: (Track) -> Node?
    
    init(engine: AVAudioEngine, makeNode: @escaping (Track) -> Node?) {
        
        self.engine = engine
        self.makeNode = makeNode
    }
    
    func compose(tracks: [Track]) -> AnyPublisher<URL, Error> {
        
        _ = tracks.map { track in
        
            let node = makeNode(track)
            node?.set(volume: track.volume)
            node?.set(rate: track.rate)
            
            return node
        }
        
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
    
    func test_composeTracks_createsNodesForTracks() {
        
        let (sut, _) = makeSUT()
        
        _ = sut.compose(tracks: [someTrack(), someTrack()])
        
        XCTAssertEqual(resultNodes.compactMap{ $0 }.count, 2)
    }
    
    func test_composeTracks_messagesNodeWithInitSetVolumeAndSetRateMessages() {
        
        let (sut, _) = makeSUT()
        
        let track = someTrack()
        _ = sut.compose(tracks: [track])
        
        XCTAssertEqual(resultNodes[0]?.messages, [.initWithData(track.data), .setVolume(track.volume), .setRate(track.rate)])
    }
    
    //MARK: - Helpers
    
    private func makeSUT(
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> (
        sut: AudioEngineComposer<AudioEnginePlayerNodeSpy>,
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
    
    private func anyTrackID() -> UUID {
        
        UUID()
    }
    
    private func anyVolume() -> Float {
        
        Float.random(in: 0...1)
    }
    
    private func anyRate() -> Float {
        
        Float.random(in: 0...1)
    }
    
    private func someTrack() -> Track {
        
        .init(id: anyTrackID(), data: anyData(), volume: anyVolume(), rate: anyRate())
    }
}
