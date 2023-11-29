//
//  ProducerTests.swift
//  
//
//  Created by Max Gribov on 31.10.2023.
//

import XCTest
import Combine
import Domain
import Processing

final class ProducerTests: XCTestCase {
    
    var cancellables = Set<AnyCancellable>()
    
    override func setUp() async throws {
        try await super.setUp()
        
        cancellables = []
    }
    
    func test_init_emptyLayers() {
        
        let (sut, _, _, _) = makeSUT()
        
        XCTAssertTrue(sut.layers.isEmpty)
    }
    
    func test_init_activeLayerIsNil() {
        
        let (sut, _, _, _) = makeSUT()
        
        XCTAssertNil(sut.active)
    }
    
    func test_init_isRecordingFalse() {
        
        let (sut, _, _, _) = makeSUT()
        let isRecordingSpy = ValueSpy(sut.isRecording())
        
        XCTAssertEqual(isRecordingSpy.values, [false])
    }
    
    func test_init_doesNotMessagePlayer() {
        
        let (_, player, _, _) = makeSUT()
        
        XCTAssertTrue(player.messages.isEmpty)
    }
    
    func test_init_doesNotMessageRecorder() {
        
        let (_, _, recorder, _) = makeSUT()
        
        XCTAssertTrue(recorder.messages.isEmpty)
    }
    
    func test_init_doesNotMessagesComposer() {
        
        let (_, _, _, composer) = makeSUT()
        
        XCTAssertEqual(composer.messages, [])
    }
    
    func test_addLayerForInstrumentWithSample_addsLayerWithCorrectPropertiesAndIncrementingNumber() {
        
        let (sut, _, _, _) = makeSUT()
        
        let firstLayerID = UUID()
        sut.addLayer(id: firstLayerID, for: .guitar, with: someSample())
        
        let secondLayerID = UUID()
        sut.addLayer(id: secondLayerID, for: .guitar, with: someSample())
        
        let thirdLayerID = UUID()
        sut.addLayer(id: thirdLayerID, for: .drums, with: someSample())
        
        XCTAssertEqual(sut.layers, [.init(id: firstLayerID, name: "Гитара 1", isPlaying: false, isMuted: false, control: .initial),
                                    .init(id: secondLayerID, name: "Гитара 2", isPlaying: false, isMuted: false, control: .initial),
                                    .init(id: thirdLayerID, name: "Ударные 1", isPlaying: false, isMuted: false, control: .initial)])
    }
    
    func test_addLayerForInstrumentWithSample_setNewLayerToActive() {
        
        let (sut, _, _, _) = makeSUT()
        
        let firstLayerID = UUID()
        sut.addLayer(id: firstLayerID, for: .guitar, with: someSample())
        XCTAssertEqual(sut.active, firstLayerID)
        
        let secondLayerID = UUID()
        sut.addLayer(id: secondLayerID, for: .guitar, with: someSample())
        XCTAssertEqual(sut.active, secondLayerID)
    }
    
    func test_addLayerForRecording_addsLayerWithCorrectPropertiesAndIncrementingNumber() {
        
        let (sut, _, _, _) = makeSUT()
        
        let firstLayerID = UUID()
        sut.addLayer(id: firstLayerID, forRecording: someRecordingData())
        
        let secondLayerID = UUID()
        sut.addLayer(id: secondLayerID, forRecording: someRecordingData())
        
        let thirdLayerID = UUID()
        sut.addLayer(id: thirdLayerID, forRecording: someRecordingData())
        
        XCTAssertEqual(sut.layers, [.init(id: firstLayerID, name: "Запись 1", isPlaying: false, isMuted: false, control: .initial),
                                    .init(id: secondLayerID, name: "Запись 2", isPlaying: false, isMuted: false, control: .initial),
                                    .init(id: thirdLayerID, name: "Запись 3", isPlaying: false, isMuted: false, control: .initial)])
    }
    
    func test_addLayerForRecording_setNewLayerToActive() {
        
        let (sut, _, _, _) = makeSUT()
        
        let firstLayerID = UUID()
        sut.addLayer(id: firstLayerID, forRecording: someRecordingData())
        XCTAssertEqual(sut.active, firstLayerID)
        
        let secondLayerID = UUID()
        sut.addLayer(id: secondLayerID, forRecording: someRecordingData())
        XCTAssertEqual(sut.active, secondLayerID)
    }
    
    func test_setIsPlayingForLayerID_updatesLayersIsPlayingState(){
        
        let (sut, _, _, _) = makeSUT()
        sut.addLayer(for: .guitar, with: someSample())
        sut.addLayer(for: .drums, with: someSample())
        sut.addLayer(forRecording: someRecordingData())
        
        sut.set(isPlaying: true, for: sut.layers[0].id)
        XCTAssertEqual(sut.layers.map(\.isPlaying), [true, false, false])
        
        sut.set(isPlaying: true, for: sut.layers[1].id)
        XCTAssertEqual(sut.layers.map(\.isPlaying), [true, true, false])
        
        sut.set(isPlaying: false, for: sut.layers[1].id)
        XCTAssertEqual(sut.layers.map(\.isPlaying), [true, false, false])
    }
    
    func test_setIsPlayingForLayerID_messagesPlayerWithPlayAndStopCommands() {
        
        let (sut, player, _, _) = makeSUT()
        let guitarSample = someSample()
        sut.addLayer(for: .guitar, with: guitarSample)
        let drumsSample = someSample()
        sut.addLayer(for: .drums, with: drumsSample)
        sut.addLayer(forRecording: someRecordingData())
        
        sut.set(isPlaying: true, for: sut.layers[0].id)
        XCTAssertEqual(player.messages, [.play(sut.layers[0].id, guitarSample.data, sut.layers[0].control)])
        
        sut.set(isPlaying: true, for: sut.layers[1].id)
        XCTAssertEqual(player.messages, [.play(sut.layers[0].id, guitarSample.data, sut.layers[0].control),
                                         .play(sut.layers[1].id, drumsSample.data, sut.layers[1].control)])
        
        sut.set(isPlaying: false, for: sut.layers[1].id)
        XCTAssertEqual(player.messages, [.play(sut.layers[0].id, guitarSample.data, sut.layers[0].control),
                                         .play(sut.layers[1].id, drumsSample.data, sut.layers[1].control),
                                         .stop(sut.layers[1].id)])
    }
    
    func test_setIsMutedForLayerID_updateLayerState() {
        
        let (sut, _, _, _) = makeSUT()
        sut.addLayer(for: .guitar, with: someSample())
        sut.addLayer(for: .drums, with: someSample())
        sut.addLayer(forRecording: someRecordingData())
        
        sut.set(isMuted: true, for: sut.layers[0].id)
        XCTAssertEqual(sut.layers.map(\.isMuted), [true, false, false])
        
        sut.set(isMuted: true, for: sut.layers[1].id)
        XCTAssertEqual(sut.layers.map(\.isMuted), [true, true, false])
        
        sut.set(isMuted: false, for: sut.layers[1].id)
        XCTAssertEqual(sut.layers.map(\.isMuted), [true, false, false])
    }
    
    func test_setIsMutedForLayerID_messagesPlayerWithPlayAndStopCommands() {
        
        let (sut, player, _, _) = makeSUT()
        let guitarSample = someSample()
        sut.addLayer(for: .guitar, with: guitarSample)
        sut.addLayer(for: .drums, with: someSample())
        sut.addLayer(forRecording: someRecordingData())
        
        sut.set(isPlaying: true, for: sut.layers[0].id)
        XCTAssertEqual(player.messages, [.play(sut.layers[0].id, guitarSample.data, sut.layers[0].control)])
        
        sut.set(isMuted: true, for: sut.layers[0].id)
        XCTAssertEqual(player.messages, [.play(sut.layers[0].id, guitarSample.data, sut.layers[0].control),
                                         .stop(sut.layers[0].id)])
        
        sut.set(isMuted: false, for: sut.layers[0].id)
        XCTAssertEqual(player.messages, [.play(sut.layers[0].id, guitarSample.data, sut.layers[0].control),
                                         .stop(sut.layers[0].id),
                                         .play(sut.layers[0].id, guitarSample.data, sut.layers[0].control)])
    }
    
    func test_deleteLayerID_removesLayerForID() {
        
        let (sut, _, _, _) = makeSUT()
        sut.addLayer(for: .guitar, with: someSample())
        sut.addLayer(for: .drums, with: someSample())
        sut.addLayer(forRecording: someRecordingData())
        
        var remainLayersIds = sut.layers.map(\.id)
        
        sut.delete(layerID: sut.layers[0].id)
        remainLayersIds.removeFirst()
        XCTAssertEqual(sut.layers.map(\.id), remainLayersIds)
        
        sut.delete(layerID: sut.layers[1].id)
        remainLayersIds.removeLast()
        XCTAssertEqual(sut.layers.map(\.id), remainLayersIds)
    }
    
    func test_deleteLayerID_setActiveToNilOnLastLayerDeleted() {
        
        let (sut, _, _, _) = makeSUT()
        sut.addLayer(for: .guitar, with: someSample())
        XCTAssertEqual(sut.active, sut.layers.first?.id)
        
        sut.delete(layerID: sut.layers.first!.id)
        
        XCTAssertNil(sut.active)
    }
    func test_deleteLayerID_setActiveToLastLayerIDOnDeleteActiveLayerAndLayersRemain() {
        
        let (sut, _, _, _) = makeSUT()
        sut.addLayer(for: .guitar, with: someSample())
        sut.addLayer(for: .drums, with: someSample())
        sut.addLayer(forRecording: someRecordingData())
        let activeLayerID = sut.layers[2].id
        XCTAssertEqual(sut.active, activeLayerID)
        
        sut.delete(layerID: sut.layers.last!.id)
        let newActiveLayerID = sut.layers[1].id
        
        XCTAssertEqual(sut.active, newActiveLayerID)
        XCTAssertNotEqual(activeLayerID, newActiveLayerID)
    }
    
    func test_deleteLayerID_doesNotChangeActiveOnDeleteNotActiveAndLayersRemain() {
        
        let (sut, _, _, _) = makeSUT()
        sut.addLayer(for: .guitar, with: someSample())
        sut.addLayer(for: .drums, with: someSample())
        sut.addLayer(forRecording: someRecordingData())
        let activeLayerID = sut.layers[2].id
        XCTAssertEqual(sut.active, activeLayerID)
        
        sut.delete(layerID: sut.layers.first!.id)
        
        XCTAssertEqual(sut.active, activeLayerID)
    }
    
    func test_deleteLayerID_messagesPlayerToStopPlayLayerWithID() {
        
        let (sut, player, _, _) = makeSUT()
        let layerID = UUID()
        sut.addLayer(id: layerID, for: .guitar, with: someSample())
        sut.set(isPlayingAll: true)
        
        sut.delete(layerID: layerID)
        
        XCTAssertEqual(player.messages.last, .stop(layerID))
    }
    
    func test_selectLayerID_doNothingOnIncorrectID() {
        
        let (sut, _, _, _) = makeSUT()
        sut.addLayer(for: .guitar, with: someSample())
        sut.addLayer(for: .drums, with: someSample())
        sut.addLayer(forRecording: someRecordingData())
        
        sut.select(layerID: UUID())
        
        XCTAssertEqual(sut.active, sut.layers[2].id)
    }
    
    func test_selectLayerID_updatesActiveLayerForCorrectLayerID() {
        
        let (sut, _, _, _) = makeSUT()
        sut.addLayer(for: .guitar, with: someSample())
        sut.addLayer(for: .drums, with: someSample())
        sut.addLayer(forRecording: someRecordingData())
        
        sut.select(layerID: sut.layers[0].id)
        
        XCTAssertEqual(sut.active, sut.layers[0].id)
    }
    
    func test_startRecording_messagesRecorder() {
        
        let (sut, _, recorder, _) = makeSUT()
        
        sut.startRecording()
        
        XCTAssertEqual(recorder.messages, [.startRecording])
    }
    
    func test_startRecording_setIsRecordingToFalseAndMessageDelegateOnFailure() {
        
        let sut = Producer(player: PlayerSpy(), recorder: AlwaysFailingRecorderStub(), composer: ComposerSpy())
        let isRecordingSpy = ValueSpy(sut.isRecording())
        let delegateSpy = ValueSpy(sut.delegateActionSubject)
        
        sut.startRecording()
        
        XCTAssertEqual(isRecordingSpy.values, [false])
        XCTAssertEqual(delegateSpy.values, [.recordingFailed])
    }
    
    func test_startRecording_setIsRecodingToTrueOnSuccess() {
        
        let (sut, _, _, _) = makeSUT()        
        let isRecordingSpy = ValueSpy(sut.isRecording())

        sut.startRecording()
        
        XCTAssertEqual(isRecordingSpy.values, [false, true])
    }
    
    func test_stopRecording_messagesRecorder() {
        
        let (sut, _, recorder, _) = makeSUT()
        
        sut.stopRecording()
        
        XCTAssertEqual(recorder.messages, [.stopRecoding])
    }
    
    func test_stopRecording_isRecordingBecomeFalseAndInformDelegate() {
        
        let (sut, _, recorder, _) = makeSUT()
        let isRecordingSpy = ValueSpy(sut.isRecording())
        let delegateSpy = ValueSpy(sut.delegateActionSubject)
        sut.startRecording()
        
        sut.stopRecording()
        recorder.recodingSubject.send(completion: .failure(anyNSError()))
        
        XCTAssertEqual(isRecordingSpy.values, [false, true, false])
        XCTAssertEqual(delegateSpy.values, [.recordingFailed])
    }
    
    func test_stopRecording_addNewRecordingLayerOnSuccess() {
        
        let (sut, player, recorder, _) = makeSUT()
        let isRecordingSpy = ValueSpy(sut.isRecording())
        sut.startRecording()
        
        sut.stopRecording()
        let recordedData = Data()
        recorder.recodingSubject.send(recordedData)
        recorder.recodingSubject.send(completion: .finished)
        
        XCTAssertEqual(isRecordingSpy.values, [false, true, false])
        XCTAssertEqual(sut.layers.first?.name, "Запись 1")
        
        sut.set(isPlaying: true, for: sut.layers[0].id)
        XCTAssertEqual(player.messagesData, [recordedData])
    }
    
    func test_setIsPlayingAll_startPlayingAllNotMutedLayersAndStopsPlayingAllLayer() {
        
        let (sut, player, _, _) = makeSUT()
        let guitarSample = someSample()
        sut.addLayer(for: .guitar, with: guitarSample)
        let drumsData = someSample()
        sut.addLayer(for: .drums, with: drumsData)
        sut.addLayer(forRecording: someRecordingData())
        sut.set(isMuted: true, for: sut.layers[2].id)
        
        sut.set(isPlayingAll: true)
        XCTAssertEqual(player.messages, [.play(sut.layers[0].id, guitarSample.data, sut.layers[0].control),
                                         .play(sut.layers[1].id, drumsData.data, sut.layers[1].control)])
        
        sut.set(isPlayingAll: false)
        XCTAssertEqual(player.messages, [.play(sut.layers[0].id, guitarSample.data, sut.layers[0].control),
                                         .play(sut.layers[1].id, drumsData.data, sut.layers[1].control),
                                         .stop(sut.layers[0].id),
                                         .stop(sut.layers[1].id)])
    }
    
    func test_setActiveLayerControl_updatesControlForActiveLayer() {
        
        let (sut, _, _, _) = makeSUT()
        sut.addLayer(forRecording: someRecordingData())
        let initialControl = sut.layers[0].control
        
        let updatedControl = Layer.Control(volume: 0, speed: 0)
        XCTAssertNotEqual(initialControl, updatedControl)
        
        sut.setActiveLayer(control: updatedControl)
        XCTAssertEqual(sut.layers[0].control, updatedControl)
    }
    
    func test_setActiveLayerControl_messagesPlayerWithUpdateForLayerIDWithControl() {
        
        let (sut, player, _, _) = makeSUT()
        let layerID = UUID()
        let recordingData = Data("recording".utf8)
        sut.addLayer(id: layerID, forRecording: recordingData)
        
        let updatedControl = Layer.Control(volume: 1, speed: 1)
        sut.setActiveLayer(control: updatedControl)
        XCTAssertEqual(player.messages, [.update(layerID, updatedControl)])
    }
    
    func test_setIsPlayingForLayerID_firesPlayingProgressOnStartPlaying() {
        
        let (sut, player, _, _) = makeSUT()
        
        expectPlayingProgressStartIncreasing(sut, on: {
            
            player.sendPlaying(event: 5)
        })
    }

    func test_setIsPlayingForLayerID_stopsPlayingProgressUpdatesOnFinishPlaying(){
        
        let (sut, player, _, _) = makeSUT()
        
        expectPlayingProgressDropsToZero(sut, on: {
            
            player.sendPlaying(event: 2)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                
                player.sendPlaying(event: nil)
            }
        })
    }
    
    func test_compose_doesNotMessagedComposerOnEmptyLayers() {
        
        let (sut, _, _, composer) = makeSUT()
        
        sut.compose()
        
        XCTAssertEqual(composer.messages, [])
    }
    
    func test_compose_messagesComposerToComposeWithTracksForNotMutedLayers() {
        
        let (sut, _, _, composer) = makeSUT()
        let notMutedLayerID = anyLayerID()
        let sample = someSample()
        sut.addLayer(id: notMutedLayerID, for: .guitar, with: sample)
        let mutedLayerID = anyLayerID()
        sut.addLayer(id: mutedLayerID, for: .drums, with: someSample())
        sut.set(isMuted: true, for: mutedLayerID)
        
        sut.compose()
        
        XCTAssertEqual(composer.messages, [.compose([.init(id: notMutedLayerID, data: sample.data, volume: 0.5, rate: 1.01)])])
    }
    
    func test_compose_stopsAllPlayingLayers() {
        
        let (sut, _, _, _) = makeSUT()
        sut.addLayer(for: .guitar, with: someSample())
        sut.addLayer(forRecording: anyData())
        sut.set(isPlayingAll: true)
        
        sut.compose()
        
        XCTAssertEqual(sut.layers[0].isPlaying, false)
        XCTAssertEqual(sut.layers[1].isPlaying, false)
    }
    
    func test_isCompositing_deliversTrueOnCompose() {
        
        let (sut, _, _, composer) = makeSUT()
        
        expect(sut, composer, isCompositing: [false, true], on: {
            
            sut.compose()
            composer.simulateIsCompositingUpdate(value: true)
        })
    }
    
    //MARK: - Helpers
    
    private func makeSUT
    (
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> (
        sut: Producer,
        player: PlayerSpy,
        recorder: RecorderSpy,
        composer: ComposerSpy
    ) {
        
        let player = PlayerSpy()
        let recorder = RecorderSpy()
        let composer = ComposerSpy()
        let sut = Producer(player: player, recorder: recorder, composer: composer)
        trackForMemoryLeaks(player, file: file, line: line)
        trackForMemoryLeaks(recorder, file: file, line: line)
        trackForMemoryLeaks(composer, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        
        return (sut, player, recorder, composer)
    }
    
    class PlayerSpy: Player {
        
        private (set) var playing = Set<Layer.ID>()
        private (set) var messages = [Message]()
        private var events = [(TimeInterval?) -> Void]()
        
        var messagesData: [Data] {
            
            messages.compactMap { message in
                
                guard case .play(_, let data, _) = message else {
                    return nil
                }
                
                return data
            }
        }
        
        enum Message: Equatable {
            case play(Layer.ID, Data, Layer.Control)
            case stop(Layer.ID)
            case update(Layer.ID, Layer.Control)
        }
        
        func play(id: Layer.ID, data: Data, control: Layer.Control) {
            
            messages.append(.play(id, data, control))
            playing.insert(id)
        }
        
        func stop(id: Layer.ID) {
            
            messages.append(.stop(id))
            playing.remove(id)
        }
        
        func update(id: Layer.ID, with control: Layer.Control) {
            
            messages.append(.update(id, control))
        }
        
        func playing(event: @escaping (TimeInterval?) -> Void) {
            
            events.append(event)
        }
        
        func sendPlaying(event: TimeInterval?, at index: Int = 0) {
            
            events[index](event)
        }
    }
    
    private class RecorderSpy: Recorder {
        
        private(set) var messages = [Message]()
        let recodingSubject = PassthroughSubject<Data, Error>()
        private let isRecordingSubject = CurrentValueSubject<Bool, Never>(false)
        
        func isRecording() -> AnyPublisher<Bool, Never> {
            
            isRecordingSubject.eraseToAnyPublisher()
        }
        
        func startRecording() -> AnyPublisher<Data, Error> {
            
            messages.append(.startRecording)
            isRecordingSubject.send(true)
            return recodingSubject.eraseToAnyPublisher()
        }
        
        func stopRecording() {
            
            messages.append(.stopRecoding)
            isRecordingSubject.send(false)
        }
        
        enum Message: Equatable {
            
            case startRecording
            case stopRecoding
        }
    }
    
    private class AlwaysFailingRecorderStub: Recorder {
        
        func isRecording() -> AnyPublisher<Bool, Never> {
            
            Just(false).eraseToAnyPublisher()
        }
        
        func startRecording() -> AnyPublisher<Data, Error> {
            
            Fail<Data, Error>(error: NSError(domain: "", code: 0)).eraseToAnyPublisher()
        }
        
        func stopRecording() {}
    }
    
    private class ComposerSpy: Composer {
        
        private(set) var messages = [Message]()
        private let isCompositingStubSubject = CurrentValueSubject<Bool, Never>.init(false)
        
        enum Message: Equatable {
            
            case compose([Track])
            case stop
        }
        
        func isCompositing() -> AnyPublisher<Bool, Never> {
            
            isCompositingStubSubject.eraseToAnyPublisher()
        }
        
        func compose(tracks: [Track]) -> AnyPublisher<URL, ComposerError> {
            
            messages.append(.compose(tracks))
            return Fail(error: ComposerError.compositingFailure).eraseToAnyPublisher()
        }
        
        func stop() {
            
            messages.append(.stop)
        }
        
        func simulateIsCompositingUpdate(value: Bool) {
            
            isCompositingStubSubject.send(value)
        }
    }
    
    private func expect(
        _ sut: Producer,
        _ composer: ComposerSpy,
        isCompositing expectedValues: [Bool],
        on action: () -> Void,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        
        sut.addLayer(for: .brass, with: someSample())
        
        var receivedValues = [Bool]()
        sut.isCompositing()
            .sink(receiveValue: { value in
                
                receivedValues.append(value)
                
            }).store(in: &cancellables)
        
        action()
        
        XCTAssertEqual(receivedValues, [false, true], file: file, line: line)
    }
    
    private func expectPlayingProgressStartIncreasing(
        _ sut: Producer,
        on action: () -> Void
    ) {
        
        let exp = expectation(description: "Wait for first progress value")
        exp.assertForOverFulfill = false
        sut.playingProgress
            .sink { progress in
                
                if progress > 0 {
                    exp.fulfill()
                }
            }
            .store(in: &cancellables)
        
        action()
        
        wait(for: [exp], timeout: 0.1)
    }
    
    private func expectPlayingProgressDropsToZero(
        _ sut: Producer,
        on action: () -> Void
    ) {
        
        let exp = expectation(description: "Wait for first progress zero")
        sut.playingProgress
            .sink { progress in
                
                if progress == 0 {
                    exp.fulfill()
                }
            }
            .store(in: &cancellables)
        
        action()
        
        wait(for: [exp], timeout: 0.2)
    }
    
    private func someSample() -> Sample {
        
        .init(id: UUID().uuidString, data: Data(UUID().uuidString.utf8))
    }
    
    private func someRecordingData() -> Data {
        
        Data(UUID().uuidString.utf8)
    }
}
