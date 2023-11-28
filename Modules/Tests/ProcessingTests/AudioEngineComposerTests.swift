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
    
    func compose(tracks: [Track]) -> AnyPublisher<URL, AudioEngineComposerError> {
        
        let nodes = tracks.map { track in
        
            let node = makeNode(track)
            node?.set(volume: track.volume)
            node?.set(rate: track.rate)
            
            return node
            
        }.compactMap { $0 }
        
        guard nodes.isEmpty == false else {
            return Fail(error: .nodesMappingFailure).eraseToAnyPublisher()
        }
        
        nodes.forEach { node in
            
            node.connect(to: engine)
        }
        
        do {
            
            try engine.start()
            nodes.forEach { node in
                
                node.schedule(offset: nil)
                node.play()
            }
            
        } catch {
            
            return Fail(error: .engineStartFailure).eraseToAnyPublisher()
        }
        
        return Fail(error: .engineStartFailure).eraseToAnyPublisher()
    }
}

enum AudioEngineComposerError: Error {
    
    case nodesMappingFailure
    case engineStartFailure
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
    
    func test_composeTracks_messagesNodeWithInitSetVolumeAndSetRateMessagesAndConnectToEngineAndScheduleAndPlay() {
        
        let (sut, _) = makeSUT()
        
        let tracks = [someTrack(), someTrack()]
        _ = sut.compose(tracks: tracks)
        
        XCTAssertEqual(resultNodes[0]?.messages, [.initWithData(tracks[0].data), .setVolume(tracks[0].volume), .setRate(tracks[0].rate), .connectToEngine, .schedule(nil), .play])
        XCTAssertEqual(resultNodes[1]?.messages, [.initWithData(tracks[1].data), .setVolume(tracks[1].volume), .setRate(tracks[1].rate), .connectToEngine, .schedule(nil), .play])
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
    
    func test_composeTracks_deliversErrorOnNodesFromTracksMappingFailure() {
        
        let (sut, _) = makeSUT()
        
        composeTracksExpect(sut, error: .nodesMappingFailure, for: [])
    }
    
    func test_composeTracks_deliversErrorOnEngineStartFailure() {
        
        let (sut, engine) = makeSUT()
        
        engine.startErrorStub = anyNSError()
        composeTracksExpect(sut, error: .engineStartFailure, for: [someTrack()])
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
    
    private func composeTracksExpect(
        _ sut: AudioEngineComposer<AudioEnginePlayerNodeSpy>,
        error expectedError: AudioEngineComposerError,
        for tracks: [Track],
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        
        _ = sut.compose(tracks: tracks)
            .sink(receiveCompletion: { completion in
                
                switch completion {
                case .finished:
                    XCTFail("Expected error", file: file, line: line)
                    
                case .failure(let receivedError):
                    XCTAssertEqual(receivedError, expectedError, file: file, line: line)
                }
                
            }, receiveValue: { _ in
                
                XCTFail("Expected error", file: file, line: line)
            })
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
