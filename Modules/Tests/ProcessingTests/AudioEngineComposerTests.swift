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
    private var nodes = [Node]()
    
    private var stateSubject = CurrentValueSubject<State, Never>(.idle)
    
    private enum State {
        
        case idle
        case compositing
        case complete(URL)
        case failure(Error)
    }
    
    init(engine: AVAudioEngine, makeNode: @escaping (Track) -> Node?, makeRecordingFile: @escaping (AVAudioFormat) throws -> AVAudioFile) {
        
        self.engine = engine
        self.makeNode = makeNode
        self.makeRecordingFile = makeRecordingFile
    }
    
    func compose(tracks: [Track]) -> AnyPublisher<URL, AudioEngineComposerError> {
        
        stateSubject.send(.idle)
        
        nodes = tracks.map { track in
        
            let node = makeNode(track)
            node?.set(volume: track.volume)
            node?.set(rate: track.rate)
            
            return node
            
        }.compactMap { $0 }
        
        guard nodes.isEmpty == false else {
            
            stateSubject.send(.failure(AudioEngineComposerError.nodesMappingFailure))
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
                    default: throw AudioEngineComposerError.compositingFailure
                    }
                }
                .mapError{ $0 as! AudioEngineComposerError }
                .eraseToAnyPublisher()
            
        } catch {
            
            stateSubject.send(.failure(error))
            return Fail(error: .engineStartFailure).eraseToAnyPublisher()
        }
    }
    
    func stop() {
        
        engine.stop()
        nodes.forEach { node in
            
            node.stop()
            node.disconnect(from: engine)
        }
        nodes = []
        
        if let url = outputRecordingFile?.url {
            
            stateSubject.send(.complete(url))
            
        } else {
            
            stateSubject.send(.failure(AudioEngineComposerError.compositingFailure))
        }
    }
}

enum AudioEngineComposerError: Error {
    
    case nodesMappingFailure
    case engineStartFailure
    case compositingFailure
}

final class AudioEngineComposerTests: XCTestCase {
    
    private var cancellables = Set<AnyCancellable>()
    private var resultNodes = [AudioEnginePlayerNodeSpy?]()
    private var outputFile: AVAudioFileSpy?
    
    override func setUp() async throws {
        try await super.setUp()
        
        cancellables = []
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
    
    func test_composeTracks_messagesOutputFileToWriteBufferOnBufferArrive() {
        
        let (sut, _, mixer) = makeSUT()
        
        _ = sut.compose(tracks: [someTrack()])
        let buffer = someAudioBuffer()
        mixer.simulateSending(buffer: buffer)
        
        XCTAssertEqual(outputFile?.messages, [.write(buffer)])
    }
    
    func test_composeTracks_deliversErrorOnOutputFileWriteFailure() {
        
        let (sut, _, mixer) = makeSUT()
        
        composeTracksExpect(sut, error: .compositingFailure, for: [someTrack()], on: {
            
            self.outputFile?.writeErrorStub = self.anyNSError()
            mixer.simulateSending(buffer: self.someAudioBuffer())
        })
    }
    
    func test_stop_deliversOutputFileURL() {
        
        let (sut, _, _) = makeSUT()
        
        let expValue = expectation(description: "Wait for value")
        sut.compose(tracks: [someTrack()])
            .sink(receiveCompletion: { completion in
                
                XCTFail("Expected finish, got \(completion) instead")
                
            }, receiveValue: { receivedURL in
                
                XCTAssertEqual(receivedURL, self.outputFileURLStub())
                expValue.fulfill()
            })
            .store(in: &cancellables)
        
        sut.stop()
        
        wait(for: [expValue], timeout: 1.0)
    }
    
    func test_stop_messagesNodesToStopAndDisconnect() {
        
        let (sut, _, _) = makeSUT()
        let tracks = [someTrack(), someTrack()]
        _ = sut.compose(tracks: tracks)
        
        sut.stop()
        
        XCTAssertEqual(resultNodes[0]?.messages, [.initWithData(tracks[0].data), .setVolume(tracks[0].volume), .setRate(tracks[0].rate), .connectToEngine, .schedule(nil), .play, .stop, .disconnectFromEngine])
        XCTAssertEqual(resultNodes[1]?.messages, [.initWithData(tracks[1].data), .setVolume(tracks[1].volume), .setRate(tracks[1].rate), .connectToEngine, .schedule(nil), .play, .stop, .disconnectFromEngine])
    }
    
    func test_stop_messagesEngineStop() {
        
        let (sut, engine, _) = makeSUT()
        let track = someTrack()
        _ = sut.compose(tracks: [track])
        
        sut.stop()
        
        XCTAssertEqual(engine.messages, [.start, .stop])
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
                
                guard let file = try? AVAudioFileSpy(forWriting: self.outputFileURLStub(), settings: format.settings) else {
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
        on action: (() -> Void)? = nil,
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
        
        action?()
    }
    
    private class AVAudioMixerNodeSpy: AVAudioMixerNode {
        
        private(set) var messages = [Message]()
        private var tapBlocks = [AVAudioNodeTapBlock]()
        
        enum Message: Equatable {
            
            case removeTap
            case installTap
        }
        
        override func removeTap(onBus bus: AVAudioNodeBus) {
            
            messages.append(.removeTap)
        }
        
        override func installTap(onBus bus: AVAudioNodeBus, bufferSize: AVAudioFrameCount, format: AVAudioFormat?, block tapBlock: @escaping AVAudioNodeTapBlock) {
            
            messages.append(.installTap)
            tapBlocks.append(tapBlock)
        }
        
        func simulateSending(buffer: AVAudioPCMBuffer, at index: Int = 0) {
            
            tapBlocks[index](buffer, .init())
        }
    }
    
    private class AVAudioFileSpy: AVAudioFile {
        
        private(set) var messages = [Message]()
        
        var writeErrorStub: Error?
        
        enum Message: Equatable {
            
            case write(AVAudioPCMBuffer)
        }
        
        override func write(from buffer: AVAudioPCMBuffer) throws {
            
            messages.append(.write(buffer))
            
            if let writeErrorStub {
                throw writeErrorStub
            }
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
    
    private func someAudioBuffer() -> AVAudioPCMBuffer {
        
        AVAudioPCMBuffer(pcmFormat: .shared, frameCapacity: .min)!
    }
}
