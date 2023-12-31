//
//  AppModelTests.swift
//  YandexCupMusicAppTests
//
//  Created by Max Gribov on 03.11.2023.
//

import XCTest
import AVFoundation
import Combine
import Domain
import Processing
import Persistence
@testable import YandexCupMusicApp

final class AppModelTests: XCTestCase {
    
    func test_init_activeLayerNil() {
        
        let (sut, _, _, _) = makeSUT()
        let activeLayerSpy = ValueSpy(sut.producer.activeLayer())
        
        XCTAssertEqual(activeLayerSpy.values, [nil])
    }
    
    func test_producerAddLayer_makeActiveLayerPublishUpdates() {
        
        let (sut, _, _, _) = makeSUT()
        let activeLayerSpy = ValueSpy(sut.producer.activeLayer())
        
        sut.producer.addLayer(forRecording: someAudioData())
        let firstLayer = sut.producer.layers.last
        XCTAssertEqual(activeLayerSpy.values, [nil, firstLayer])
        
        sut.producer.addLayer(forRecording: someOtherAudioData())
        let secondLayer = sut.producer.layers.last
        XCTAssertEqual(activeLayerSpy.values, [nil, firstLayer, secondLayer])
        
        sut.producer.delete(layerID: secondLayer!.id)
        XCTAssertEqual(activeLayerSpy.values, [nil, firstLayer, secondLayer, firstLayer])
        
        sut.producer.delete(layerID: firstLayer!.id)
        XCTAssertEqual(activeLayerSpy.values, [nil, firstLayer, secondLayer, firstLayer, nil])
    }
    
    func test_sampleIDs_retrievesSampleIDsFromLocalStore() {
        
        let (sut, _, _, _) = makeSUT()

        let sampleIDsSpy = ValueSpy(sut.localStore.sampleIDs(for: .brass))
        
        XCTAssertEqual(sampleIDsSpy.values, [SamplesLocalStoreSpyStub.stabbedSamplesIDs])
    }
    
    func test_loadSample_retrievesSampleFromLocalStore() {
        
        let (sut, _, _, _) = makeSUT()

        let loadSampleSpy = ValueSpy(sut.localStore.loadSample(sampleID: anySampleID()))
        
        XCTAssertEqual(loadSampleSpy.values, [SamplesLocalStoreSpyStub.stabbedSample])
    }
    
    func test_producerAddLayer_makeLayersPublishUpdates() {
        
        let (sut, _, _, _) = makeSUT()
        let layersSpy = ValueSpy(sut.producer.layers())
        
        XCTAssertEqual(layersSpy.values, [.init(layers: [], active: nil)])
        
        sut.producer.addLayer(forRecording: someAudioData())
        let firstLayer = sut.producer.layers[0]
        XCTAssertEqual(layersSpy.values, [.init(layers: [], active: nil),
                                          .init(layers: [firstLayer], active: nil),
                                          .init(layers: [firstLayer], active: firstLayer.id)])
    }
    
    func test_bindMainViewModelDelegate_requestSampleFromLocalStoreAndAddLayerToProducerOnActionAddLayerWithDefaultSampleForInstrument() {
        
        let (sut, _, _, _) = makeSUT()
        let mainViewModelDelegateStub = PassthroughSubject<MainViewModel.DelegateAction, Never>()
        sut.bindMainViewModel(delegate: mainViewModelDelegateStub.eraseToAnyPublisher())
        
        mainViewModelDelegateStub.send(.defaultSampleSelected(.guitar))
        
        XCTAssertEqual(sut.localStore.messages, [.retrieveSamplesIDs(.guitar), .retrieveSample(SamplesLocalStoreSpyStub.stabbedSamplesIDs[0])])
        XCTAssertEqual(sut.producer.layers.count, 1)
    }
    
    func test_layerDelegateActions_affectsProducerLayersState() {

        let (sut, _, _, _) = makeSUT()
        let mainViewModelDelegateStub = PassthroughSubject<MainViewModel.DelegateAction, Never>()
        sut.bindMainViewModel(delegate: mainViewModelDelegateStub.eraseToAnyPublisher())
        sut.producer.addLayer(forRecording: someAudioData())
        sut.producer.addLayer(forRecording: someOtherAudioData())
        let firstLayerID = sut.producer.layers[0].id
        let secondLayerID = sut.producer.layers[1].id
        
        XCTAssertFalse(sut.producer.layers[0].isPlaying)
        mainViewModelDelegateStub.send(.layersControl(.isPlayingDidChanged(firstLayerID, true)))
        XCTAssertTrue(sut.producer.layers[0].isPlaying)
        
        mainViewModelDelegateStub.send(.layersControl(.isPlayingDidChanged(firstLayerID, false)))
        XCTAssertFalse(sut.producer.layers[0].isPlaying)
        
        XCTAssertFalse(sut.producer.layers[0].isMuted)
        mainViewModelDelegateStub.send(.layersControl(.isMutedDidChanged(firstLayerID, true)))
        XCTAssertTrue(sut.producer.layers[0].isMuted)
        
        mainViewModelDelegateStub.send(.layersControl(.isMutedDidChanged(firstLayerID, false)))
        XCTAssertFalse(sut.producer.layers[0].isMuted)
        
        XCTAssertEqual(sut.producer.active, secondLayerID)
        mainViewModelDelegateStub.send(.layersControl(.selectLayer(firstLayerID)))
        XCTAssertEqual(sut.producer.active, firstLayerID)
        
        XCTAssertEqual(sut.producer.layers.count, 2)
        mainViewModelDelegateStub.send(.layersControl(.deleteLayer(firstLayerID)))
        XCTAssertEqual(sut.producer.layers.count, 1)
    }
    
    func test_startStopPlayMainViewModelDelegateActions_togglesAllLayersIsPlayingState() {
        
        let (sut, _, _, _) = makeSUT()
        let mainViewModelDelegateStub = PassthroughSubject<MainViewModel.DelegateAction, Never>()
        sut.bindMainViewModel(delegate: mainViewModelDelegateStub.eraseToAnyPublisher())
        sut.producer.addLayer(forRecording: someAudioData())
        sut.producer.addLayer(forRecording: someOtherAudioData())
        XCTAssertEqual(sut.producer.layers.map(\.isPlaying), [false, false])
        
        mainViewModelDelegateStub.send(.startPlaying)
        XCTAssertEqual(sut.producer.layers.map(\.isPlaying), [true, true])
        
        mainViewModelDelegateStub.send(.stopPlaying)
        XCTAssertEqual(sut.producer.layers.map(\.isPlaying), [false, false])
    }
    
    func test_activeLayerControlUpdateDelegateAction_updatesControlForActiveLayer() {
        
        let (sut, _, _, _) = makeSUT()
        let mainViewModelDelegateStub = PassthroughSubject<MainViewModel.DelegateAction, Never>()
        sut.bindMainViewModel(delegate: mainViewModelDelegateStub.eraseToAnyPublisher())
        sut.producer.addLayer(forRecording: someAudioData())
        
        let updatedControl = Layer.Control(volume: 0, speed: 0)
        mainViewModelDelegateStub.send(.activeLayerUpdate(updatedControl))
        
        XCTAssertEqual(sut.producer.layers.first?.control, updatedControl)
    }
    
    func test_sampleSelectedInstrumentAction_retrievesSampleFromLocalStore() {
        
        let (sut, _, _, _) = makeSUT()
        let mainViewModelDelegateStub = PassthroughSubject<MainViewModel.DelegateAction, Never>()
        sut.bindMainViewModel(delegate: mainViewModelDelegateStub.eraseToAnyPublisher())
        
        let sampleID = Sample.ID()
        mainViewModelDelegateStub.send(.sampleSelector(.sampleDidSelected(sampleID, .drums)))
        
        XCTAssertEqual(sut.localStore.messages, [.retrieveSample(sampleID)])
    }
    
    func test_sampleSelectedInstrumentAction_addLayerOnSuccessSampleLoading() {
        
        let (sut, _, _, _) = makeSUT()
        let mainViewModelDelegateStub = PassthroughSubject<MainViewModel.DelegateAction, Never>()
        sut.bindMainViewModel(delegate: mainViewModelDelegateStub.eraseToAnyPublisher())
        
        let sampleID = Sample.ID()
        mainViewModelDelegateStub.send(.sampleSelector(.sampleDidSelected(sampleID, .drums)))
        
        XCTAssertEqual(sut.producer.layers.count, 1)
    }
    
    func test_startRecording_requestsRecordPermissionOnFirstAttempt() {
        
        let (sut, session, _, _) = makeSUT()
        let mainViewModelDelegateStub = PassthroughSubject<MainViewModel.DelegateAction, Never>()
        sut.bindMainViewModel(delegate: mainViewModelDelegateStub.eraseToAnyPublisher())
        
        mainViewModelDelegateStub.send(.startRecording)
        
        XCTAssertEqual(session.messages, [.recordPermissionRequest])
    }
    
    func test_startRecording_startsRecordingOnPermissionsGranted() {
        
        let (sut, session, _, _) = makeSUT()
        let mainViewModelDelegateStub = PassthroughSubject<MainViewModel.DelegateAction, Never>()
        sut.bindMainViewModel(delegate: mainViewModelDelegateStub.eraseToAnyPublisher())
        let isRecordingSpy = ValueSpy(sut.producer.isRecording())
        
        mainViewModelDelegateStub.send(.startRecording)
        session.sendResponse(true)
        
        XCTAssertEqual(isRecordingSpy.values, [false, true])
    }
    
    func test_stopRecording_stopsPreviouslyStartedRecording() throws{
        
        let (sut, session, recorder, _) = makeSUT()
        let mainViewModelDelegateStub = PassthroughSubject<MainViewModel.DelegateAction, Never>()
        sut.bindMainViewModel(delegate: mainViewModelDelegateStub.eraseToAnyPublisher())
        let isRecordingSpy = ValueSpy(sut.producer.isRecording())
        mainViewModelDelegateStub.send(.startRecording)
        session.sendResponse(true)
        
        mainViewModelDelegateStub.send(.stopRecording)
        recorder.audioRecorderDidFinishRecording(try makeAVAudioRecorderStub(), successfully: true)
        
        XCTAssertEqual(isRecordingSpy.values, [false, true, false])
    }
    
    func test_startCompositingDelegateAction_messagesComposerToCompose() {
        
        let (sut, _, _, composer) = makeSUT()
        let mainViewModelDelegateStub = PassthroughSubject<MainViewModel.DelegateAction, Never>()
        sut.bindMainViewModel(delegate: mainViewModelDelegateStub.eraseToAnyPublisher())
        sut.producer.addLayer(forRecording: someAudioData())
        sut.producer.addLayer(forRecording: someOtherAudioData())
        
        mainViewModelDelegateStub.send(.startComposing)
        
        XCTAssertEqual(composer.messages, [.compose])
    }
    
    func test_stopCompositingDelegateAction_messagesComposerToStop() {
        
        let (sut, _, _, composer) = makeSUT()
        let mainViewModelDelegateStub = PassthroughSubject<MainViewModel.DelegateAction, Never>()
        sut.bindMainViewModel(delegate: mainViewModelDelegateStub.eraseToAnyPublisher())
        sut.producer.addLayer(forRecording: someAudioData())
        sut.producer.addLayer(forRecording: someOtherAudioData())
        mainViewModelDelegateStub.send(.startComposing)
        
        mainViewModelDelegateStub.send(.stopComposing)
        
        XCTAssertEqual(composer.messages, [.compose, .stop])
    }

    private func makeSUT(
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> (sut: AppModel<SamplesLocalStoreSpyStub, SessionSpy, FoundationPlayer<AudioPlayerDummy>, FoundationRecorder<AudioRecorderDummy>, ComposerSpy>, session: SessionSpy, recorder: FoundationRecorder<AudioRecorderDummy>, composer: ComposerSpy) {
        
        let sessionSpy = SessionSpy()
        let recorder = FoundationRecorder(makeRecorder: { url, format in try AudioRecorderDummy(url: url, format: format) })
        let composer = ComposerSpy()
        let sut = AppModel(
            producer: Producer(
                player: FoundationPlayer(makePlayer: { data in try AudioPlayerDummy(data: data) }),
                recorder: recorder,
                composer: composer
            ),
            localStore: SamplesLocalStoreSpyStub(),
            sessionConfigurator: FoundationRecordingSessionConfigurator(session: sessionSpy)
        )
        
        trackForMemoryLeaks(sut, file: file, line: line)
        trackForMemoryLeaks(sessionSpy, file: file, line: line)
        
        return (sut, sessionSpy, recorder, composer)
    }
    
    private class ComposerSpy: Composer {
        
        private(set) var messages = [Message]()
        
        enum Message: Equatable {
            
            case compose
            case stop
        }
        
        func isCompositing() -> AnyPublisher<Bool, Never> {
            
            Just(false).eraseToAnyPublisher()
        }
        
        func compose(tracks: [Processing.Track]) -> AnyPublisher<URL, Processing.ComposerError> {
            
            messages.append(.compose)
            return Fail(error: Processing.ComposerError.compositingFailure).eraseToAnyPublisher()
        }
        
        func stop() {
            messages.append(.stop)
        }
    }
    
    private class AudioPlayerDummy: AVAudioPlayerProtocol {
        
        var volume: Float
        var enableRate: Bool
        var rate: Float
        var numberOfLoops: Int
        var currentTime: TimeInterval
        var duration: TimeInterval { 1 }
        
        required init(data: Data) throws {
            
            volume = 0
            enableRate = false
            rate = 0
            numberOfLoops = 0
            currentTime = 0
        }
        
        func play() -> Bool { false }
        func stop() {}
        
    }
    
    private class AudioRecorderDummy: AVAudioRecorderProtocol {
        
        var delegate: AVAudioRecorderDelegate?

        required init(url: URL, format: AVAudioFormat) throws {}
        
        func record() -> Bool { false }
        func stop() {}
    }
    
    private class SamplesLocalStoreSpyStub: SamplesLocalStore {
        
        private(set) var messages = [Message]()
        
        enum Message: Equatable {
            case retrieveSamplesIDs(Instrument)
            case retrieveSample(Sample.ID)
        }
        
        func retrieveSamplesIDs(for instrument: Domain.Instrument, complete: @escaping (Result<[Domain.Sample.ID], Error>) -> Void) {
            
            messages.append(.retrieveSamplesIDs(instrument))
            complete(.success(Self.stabbedSamplesIDs))
        }
        
        func retrieveSample(for sampleID: Domain.Sample.ID, completion: @escaping (Result<Domain.Sample, Error>) -> Void) {
            
            messages.append(.retrieveSample(sampleID))
            completion(.success(Self.stabbedSample))
        }
        
        static let stabbedSamplesIDs = ["sample1", "sample2", "sample3"]
        static let stabbedSample = Sample(id: UUID().uuidString, data: Data(UUID().uuidString.utf8))
    }
    
    private class SessionSpy: AVAudioSessionProtocol {

        private(set) var messages = [Message]()
        private var responses = [(Bool) -> Void]()
        
        enum Message: Equatable {
            
            case recordPermissionRequest
        }

        func setCategory(_ category: AVAudioSession.Category, mode: AVAudioSession.Mode, options: AVAudioSession.CategoryOptions) throws {}
        
        func setActive(_ active: Bool, options: AVAudioSession.SetActiveOptions) throws {}
        
        func requestRecordPermission(_ response: @escaping (Bool) -> Void) {
            
            messages.append(.recordPermissionRequest)
            responses.append(response)
        }
        
        func sendResponse(_ value: Bool, at index: Int = 0) {
            
            responses[index](value)
        }
        
        func overrideOutputAudioPort(_ portOverride: AVAudioSession.PortOverride) throws {
        }
    }
    
    private func anySampleID() -> Sample.ID { UUID().uuidString }
    
    private func someAudioData() -> Data { Data("some-audio-data".utf8) }
    private func someOtherAudioData() -> Data { Data("some-other-audio-data".utf8) }
    
    private func makeAVAudioRecorderStub() throws -> AVAudioRecorder {
        
        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("recording.m4a")
        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 12000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        try Data().write(to: url)
        
        return try AVAudioRecorder(url: url, settings: settings)
    }
}
