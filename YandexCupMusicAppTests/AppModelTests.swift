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

final class AppModel<S> where S: SamplesLocalStore {
    
    let producer: Producer
    let localStore: S
    
    init(producer: Producer, localStore: S) {
        
        self.producer = producer
        self.localStore = localStore
    }
    
    func activeLayer() -> AnyPublisher<Layer?, Never> {
        
        producer
            .$layers
            .zip(producer.$active)
            .map { layers, activeLayerID in
                
                guard let activeLayerID, let layer = layers.first(where: { $0.id == activeLayerID }) else {
                    return nil
                }
                
                return layer
                
            }.eraseToAnyPublisher()
    }
    
    func sampleIDs(for instrument: Instrument) -> AnyPublisher<[Sample.ID], Error> {
        
        Deferred {
            
            Future { [weak self] promise in
                
                self?.localStore.retrieveSamplesIDs(for: instrument, complete: promise)
            }
            
        }.eraseToAnyPublisher()
    }
}


final class AppModelTests: XCTestCase {
    
    var cancellables = Set<AnyCancellable>()
    
    override func setUp() async throws {
        try await super.setUp()
        
        cancellables = []
    }

    func test_init_activeLayerNil() {
        
        let sut = makeSUT()
        let activeLayerSpy = ValueSpy(sut.activeLayer())
        
        XCTAssertEqual(activeLayerSpy.values, [nil])
    }
    
    func test_producerAddLayer_makeActiveLayerPublishUpdates() {
        
        let sut = makeSUT()
        let activeLayerSpy = ValueSpy(sut.activeLayer())
        
        sut.producer.addLayer(forRecording: Data("some data".utf8))
        let firstLayer = sut.producer.layers.first
        XCTAssertEqual(activeLayerSpy.values, [nil, firstLayer])
        
        sut.producer.addLayer(forRecording: Data("some other data".utf8))
        let secondLayer = sut.producer.layers.first
        XCTAssertEqual(activeLayerSpy.values, [nil, firstLayer, secondLayer])
        
        sut.producer.delete(layerID: secondLayer!.id)
        XCTAssertEqual(activeLayerSpy.values, [nil, firstLayer, secondLayer, firstLayer])
        
        sut.producer.delete(layerID: firstLayer!.id)
        XCTAssertEqual(activeLayerSpy.values, [nil, firstLayer, secondLayer, firstLayer, nil])
    }
    
    func test_sampleIDs_retrievesSampleIDsFromLocalStore() {
        
        let sut = makeSUT()
        
        var receivedResult: [Sample.ID]? = nil
        sut.sampleIDs(for: .brass)
            .sink(receiveCompletion: { _ in }) { result in
                receivedResult = result
            }.store(in: &cancellables)
        
        XCTAssertEqual(receivedResult, SamplesLocalStoreStub.stabbedSamplesIDs)
    }

    private func makeSUT(
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> AppModel<SamplesLocalStoreStub> {
        
        let sut = AppModel(
            producer: Producer(
                player: FoundationPlayer(makePlayer: { data in try AudioPlayerDummy(data: data) }),
                recorder: FoundationRecorder(makeRecorder: { url, settings in try AudioRecorderDummy(url: url, settings: settings) })),
            localStore: SamplesLocalStoreStub()
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
    
    private class SamplesLocalStoreStub: SamplesLocalStore {
        
        func retrieveSamplesIDs(for instrument: Domain.Instrument, complete: @escaping (Result<[Domain.Sample.ID], Error>) -> Void) {
            
            complete(.success(Self.stabbedSamplesIDs))
        }
        
        func retrieveSample(for sampleID: Domain.Sample.ID, completion: @escaping (Result<Domain.Sample, Error>) -> Void) {
            
        }
        
        static let stabbedSamplesIDs = ["sample1", "sample2", "sample3"]
    }
    
}
