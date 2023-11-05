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
    
    var cancellables = Set<AnyCancellable>()
    
    override func setUp() async throws {
        try await super.setUp()
        
        cancellables = []
    }

    func test_init_activeLayerNil() {
        
        let sut = makeSUT()
        let activeLayerSpy = ValueSpy(sut.producer.activeLayer())
        
        XCTAssertEqual(activeLayerSpy.values, [nil])
    }
    
    func test_producerAddLayer_makeActiveLayerPublishUpdates() {
        
        let sut = makeSUT()
        let activeLayerSpy = ValueSpy(sut.producer.activeLayer())
        
        sut.producer.addLayer(forRecording: Data("some data".utf8))
        let firstLayer = sut.producer.layers.last
        XCTAssertEqual(activeLayerSpy.values, [nil, firstLayer])
        
        sut.producer.addLayer(forRecording: Data("some other data".utf8))
        let secondLayer = sut.producer.layers.last
        XCTAssertEqual(activeLayerSpy.values, [nil, firstLayer, secondLayer])
        
        sut.producer.delete(layerID: secondLayer!.id)
        XCTAssertEqual(activeLayerSpy.values, [nil, firstLayer, secondLayer, firstLayer])
        
        sut.producer.delete(layerID: firstLayer!.id)
        XCTAssertEqual(activeLayerSpy.values, [nil, firstLayer, secondLayer, firstLayer, nil])
    }
    
    func test_sampleIDs_retrievesSampleIDsFromLocalStore() {
        
        let sut = makeSUT()
        
        var receivedResult: [Sample.ID]? = nil
        sut.localStore.sampleIDs(for: .brass)
            .sink(receiveCompletion: { _ in }) { result in
                receivedResult = result
            }.store(in: &cancellables)
        
        XCTAssertEqual(receivedResult, SamplesLocalStoreSpyStub.stabbedSamplesIDs)
    }
    
    func test_loadSample_retrievesSampleFromLocalStore() {
        
        let sut = makeSUT()
        
        var receivedResult: Sample? = nil
        sut.localStore.loadSample(sampleID: anySampleID())
            .sink(receiveCompletion: { _ in }) { result in
                receivedResult = result
            }.store(in: &cancellables)
        
        XCTAssertEqual(receivedResult, SamplesLocalStoreSpyStub.stabbedSample)
    }
    
    func test_producerAddLayer_makeLayersPublishUpdates() {
        
        let sut = makeSUT()
        let layersSpy = ValueSpy(sut.producer.layers())
        
        XCTAssertEqual(layersSpy.values, [.init(layers: [], active: nil)])
        
        sut.producer.addLayer(forRecording: Data("some data".utf8))
        let firstLayer = sut.producer.layers[0]
        XCTAssertEqual(layersSpy.values, [.init(layers: [], active: nil),
                                          .init(layers: [firstLayer], active: nil),
                                          .init(layers: [firstLayer], active: firstLayer.id)])
    }
    
    func test_bindMainViewModelDelegate_requestSampleFromLocalStoreAndAddLayerToProducerOnActionAddLayerWithDefaultSampleForInstrument() {
        
        let sut = makeSUT()
        let mainViewModelDelegateStub = PassthroughSubject<MainViewModel.DelegateAction, Never>()
        sut.bindMainViewModel(delegate: mainViewModelDelegateStub.eraseToAnyPublisher())
        
        mainViewModelDelegateStub.send(.defaultSampleSelected(.guitar))
        
        XCTAssertEqual(sut.localStore.messages, [.retrieveSamplesIDs(.guitar), .retrieveSample(SamplesLocalStoreSpyStub.stabbedSamplesIDs[0])])
        XCTAssertEqual(sut.producer.layers.count, 1)
    }
    
    func test_layerDelegateActions_affectsProducerLayersState() {

        let sut = makeSUT()
        let mainViewModelDelegateStub = PassthroughSubject<MainViewModel.DelegateAction, Never>()
        sut.bindMainViewModel(delegate: mainViewModelDelegateStub.eraseToAnyPublisher())
        sut.producer.addLayer(forRecording: Data("some-audio-data".utf8))
        sut.producer.addLayer(forRecording: Data("some-other-audio-data".utf8))
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
        
        let sut = makeSUT()
        let mainViewModelDelegateStub = PassthroughSubject<MainViewModel.DelegateAction, Never>()
        sut.bindMainViewModel(delegate: mainViewModelDelegateStub.eraseToAnyPublisher())
        sut.producer.addLayer(forRecording: Data("some-audio-data".utf8))
        sut.producer.addLayer(forRecording: Data("some-other-audio-data".utf8))
        XCTAssertEqual(sut.producer.layers.map(\.isPlaying), [false, false])
        
        mainViewModelDelegateStub.send(.startPlaying)
        XCTAssertEqual(sut.producer.layers.map(\.isPlaying), [true, true])
        
        mainViewModelDelegateStub.send(.stopPlaying)
        XCTAssertEqual(sut.producer.layers.map(\.isPlaying), [false, false])
    }
    
    func test_activeLayerControlUpdateDelegateAction_updatesControlForActiveLayer() {
        
        let sut = makeSUT()
        let mainViewModelDelegateStub = PassthroughSubject<MainViewModel.DelegateAction, Never>()
        sut.bindMainViewModel(delegate: mainViewModelDelegateStub.eraseToAnyPublisher())
        sut.producer.addLayer(forRecording: Data("some-audio-data".utf8))
        
        let updatedControl = Layer.Control(volume: 0, speed: 0)
        mainViewModelDelegateStub.send(.activeLayerUpdate(updatedControl))
        
        XCTAssertEqual(sut.producer.layers.first?.control, updatedControl)
    }
    
    func test_sampleSelectedInstrumentAction_retrievesSampleFromLocalStore() {
        
        let sut = makeSUT()
        let mainViewModelDelegateStub = PassthroughSubject<MainViewModel.DelegateAction, Never>()
        sut.bindMainViewModel(delegate: mainViewModelDelegateStub.eraseToAnyPublisher())
        
        let sampleID = Sample.ID()
        mainViewModelDelegateStub.send(.sampleSelector(.sampleDidSelected(sampleID, .drums)))
        
        XCTAssertEqual(sut.localStore.messages, [.retrieveSample(sampleID)])
    }
    
    func test_sampleSelectedInstrumentAction_addLayerOnSuccessSampleLoading() {
        
        let sut = makeSUT()
        let mainViewModelDelegateStub = PassthroughSubject<MainViewModel.DelegateAction, Never>()
        sut.bindMainViewModel(delegate: mainViewModelDelegateStub.eraseToAnyPublisher())
        
        let sampleID = Sample.ID()
        mainViewModelDelegateStub.send(.sampleSelector(.sampleDidSelected(sampleID, .drums)))
        
        XCTAssertEqual(sut.producer.layers.count, 1)
    }
    
    func test_startRecording_requestsRecordPermissionOnFirstAttempt() {
        
        let sessionSpy = SessionSpy()
        let sut = makeSUT(sessionSpy: sessionSpy)
        let mainViewModelDelegateStub = PassthroughSubject<MainViewModel.DelegateAction, Never>()
        sut.bindMainViewModel(delegate: mainViewModelDelegateStub.eraseToAnyPublisher())
        
        mainViewModelDelegateStub.send(.startRecording)
        
        XCTAssertEqual(sessionSpy.messages, [.recordPermissionRequest])
    }
    
    func test_startRecording_startsRecordingOnPermissionsGranted() {
        
        let sessionSpy = SessionSpy()
        let sut = makeSUT(sessionSpy: sessionSpy)
        let mainViewModelDelegateStub = PassthroughSubject<MainViewModel.DelegateAction, Never>()
        sut.bindMainViewModel(delegate: mainViewModelDelegateStub.eraseToAnyPublisher())
        let isRecordingSpy = ValueSpy(sut.producer.isRecording())
        
        mainViewModelDelegateStub.send(.startRecording)
        sessionSpy.sendResponse(true)
        
        XCTAssertEqual(isRecordingSpy.values, [false, true])
    }

    private func makeSUT(
        sessionSpy: SessionSpy = .init(),
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> AppModel<SamplesLocalStoreSpyStub, SessionSpy> {
        
        let sut = AppModel(
            producer: Producer(
                player: FoundationPlayer(makePlayer: { data in try AudioPlayerDummy(data: data) }),
                recorder: FoundationRecorder(makeRecorder: { url, settings in try AudioRecorderDummy(url: url, settings: settings) })),
            localStore: SamplesLocalStoreSpyStub(),
            sessionConfigurator: FoundationRecordingSessionConfigurator(session: sessionSpy)
        )
        
        trackForMemoryLeaks(sut, file: file, line: line)
        
        return sut
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

        required init(url: URL, settings: [String : Any]) throws { }
        
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
    }
    
    private func anySampleID() -> Sample.ID { UUID().uuidString }
    
}
