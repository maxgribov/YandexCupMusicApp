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
        
        let nodes = tracks.map { track in
        
            let node = makeNode(track)
            node?.set(volume: track.volume)
            node?.set(rate: track.rate)
            
            return node
            
        }.compactMap { $0 }
        
        guard nodes.isEmpty == false else {
            return Fail(error: NSError(domain: "", code: 0)).eraseToAnyPublisher()
        }
        
        nodes.forEach { node in
            
            node.connect(to: engine)
        }
        
        do {
            
            try engine.start()
            
        } catch {
            
            return Fail(error: NSError(domain: "", code: 0)).eraseToAnyPublisher()
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
    
    func test_composeTracks_messagesNodeWithInitSetVolumeAndSetRateMessagesAndConnectToEngine() {
        
        let (sut, _) = makeSUT()
        
        let tracks = [someTrack(), someTrack()]
        _ = sut.compose(tracks: tracks)
        
        XCTAssertEqual(resultNodes[0]?.messages, [.initWithData(tracks[0].data), .setVolume(tracks[0].volume), .setRate(tracks[0].rate), .connectToEngine])
        XCTAssertEqual(resultNodes[1]?.messages, [.initWithData(tracks[1].data), .setVolume(tracks[1].volume), .setRate(tracks[1].rate), .connectToEngine])
    }
    
    func test_composeTracks_doesNotMessagesEngineOnEmptyNodesList() {
        
        let (sut, engine) = makeSUT()
        
        _ = sut.compose(tracks: [])
        
        XCTAssertEqual(engine.messages, [])
    }
    
    func test_composeTracks_messagesEngineWithStartOnNotEmptyNodesList() {
        
        let (sut, engine) = makeSUT()
        
        _ = sut.compose(tracks: [someTrack()])
        
        XCTAssertEqual(engine.messages, [.start])
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
