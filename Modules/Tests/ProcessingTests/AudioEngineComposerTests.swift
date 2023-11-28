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
    private let makeRecordingFile: (AVAudioFormat) throws -> AVAudioFile
    private var outputRecordingFile: AVAudioFile?
    
    init(engine: AVAudioEngine, makeNode: @escaping (Track) -> Node?, makeRecordingFile: @escaping (AVAudioFormat) throws -> AVAudioFile) {
        
        self.engine = engine
        self.makeNode = makeNode
        self.makeRecordingFile = makeRecordingFile
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
            
            let outputFormat = engine.mainMixerNode.outputFormat(forBus: 0)
            outputRecordingFile = try makeRecordingFile(outputFormat)
            engine.mainMixerNode.removeTap(onBus: 0)
            engine.mainMixerNode.installTap(onBus: 0, bufferSize: 1023, format: outputFormat) { [weak self] buffer, _ in
                
                try? self?.outputRecordingFile?.write(from: buffer)
            }
            
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
    
    private var resultNodes = [AudioEnginePlayerNodeSpy?]()
    private var outputFile: AVAudioFile?
    
    override func setUp() async throws {
        try await super.setUp()
        
        resultNodes = []
        outputFile = nil
    }

    func test_init_doesNotMessagesEngine() {
        
        let (_, engine, _) = makeSUT()
        
        XCTAssertEqual(engine.messages, [])
    }
    
    func test_composeTracks_messagesNodeWithInitSetVolumeAndSetRateMessagesAndConnectToEngineAndScheduleAndPlay() {
        
        let (sut, _, _) = makeSUT()
        
        let tracks = [someTrack(), someTrack()]
        _ = sut.compose(tracks: tracks)
        
        XCTAssertEqual(resultNodes[0]?.messages, [.initWithData(tracks[0].data), .setVolume(tracks[0].volume), .setRate(tracks[0].rate), .connectToEngine, .schedule(nil), .play])
        XCTAssertEqual(resultNodes[1]?.messages, [.initWithData(tracks[1].data), .setVolume(tracks[1].volume), .setRate(tracks[1].rate), .connectToEngine, .schedule(nil), .play])
    }
    
    func test_composeTracks_doesNotMessagesEngineOnEmptyNodesList() {
        
        let (sut, engine, _) = makeSUT()
        
        _ = sut.compose(tracks: [])
        
        XCTAssertEqual(engine.messages, [])
    }
    
    func test_composeTracks_messagesEngineWithStartOnNotEmptyNodesList() {
        
        let (sut, engine, _) = makeSUT()
        
        _ = sut.compose(tracks: [someTrack()])
        
        XCTAssertEqual(engine.messages, [.start])
    }
    
    func test_composeTracks_deliversErrorOnNodesFromTracksMappingFailure() {
        
        let (sut, _, _) = makeSUT()
        
        composeTracksExpect(sut, error: .nodesMappingFailure, for: [])
    }
    
    func test_composeTracks_deliversErrorOnEngineStartFailure() {
        
        let (sut, engine, _) = makeSUT()
        
        engine.startErrorStub = anyNSError()
        composeTracksExpect(sut, error: .engineStartFailure, for: [someTrack()])
    }
    
    func test_composeTracks_createsOutputAudioFile() {
        
        let (sut, _, _) = makeSUT()
        
        _ = sut.compose(tracks: [someTrack()])
        
        XCTAssertNotNil(outputFile)
        XCTAssertEqual(outputFile?.url, outputFileURLStub())
    }
    
    func test_composeTracks_messagesEngineMainMixerNodeToRemoveTapAndThenInstallTap() {
        
        let (sut, _, mixer) = makeSUT()
        
        _ = sut.compose(tracks: [someTrack()])
        
        XCTAssertEqual(mixer.messages, [.removeTap, .installTap])
    }
    
    //MARK: - Helpers
    
    private func makeSUT(
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> (
        sut: AudioEngineComposer<AudioEnginePlayerNodeSpy>,
        engine: AVAudioEngineSpy,
        mixer: AVAudioMixerNodeSpy
    ) {
        
        let engine = AVAudioEngineSpy()
        let mixer = AVAudioMixerNodeSpy()
        engine.mainMixerNodeStub = mixer
        let sut = AudioEngineComposer(
            engine: engine,
            makeNode: { track in
                
                let node = AudioEnginePlayerNodeSpy(with: track.data)
                self.resultNodes.append(node)
                
                return node
                
            },
            makeRecordingFile: { format in
                
                guard let file = try? AVAudioFile(forWriting: self.outputFileURLStub(), settings: format.settings) else {
                    throw self.anyNSError()
                }
                
                self.outputFile = file
                
                return file
            }
        )
        
        trackForMemoryLeaks(sut, file: file, line: line)
        trackForMemoryLeaks(engine, file: file, line: line)
        trackForMemoryLeaks(mixer, file: file, line: line)
        
        return (sut, engine, mixer)
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
    
    private class AVAudioMixerNodeSpy: AVAudioMixerNode {
        
        private(set) var messages = [Message]()
        
        enum Message: Equatable {
            
            case removeTap
            case installTap
        }
        
        override func removeTap(onBus bus: AVAudioNodeBus) {
            
            messages.append(.removeTap)
        }
        
        override func installTap(onBus bus: AVAudioNodeBus, bufferSize: AVAudioFrameCount, format: AVAudioFormat?, block tapBlock: @escaping AVAudioNodeTapBlock) {
            
            messages.append(.installTap)
        }
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
    
    private func outputFileURLStub() -> URL {
        
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("composition.m4a")
    }
}
