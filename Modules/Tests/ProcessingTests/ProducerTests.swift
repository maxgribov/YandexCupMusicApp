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
    
    private var playingProgressBinding: AnyCancellable?
    
    override func setUp() async throws {
        try await super.setUp()
        
        playingProgressBinding = nil
    }
    
    func test_init_emptyLayers() {
        
        let (sut, _, _) = makeSUT()
        
        XCTAssertTrue(sut.layers.isEmpty)
    }
    
    func test_init_activeLayerIsNil() {
        
        let (sut, _, _) = makeSUT()
        
        XCTAssertNil(sut.active)
    }
    
    func test_init_isRecordingFalse() {
        
        let (sut, _, _) = makeSUT()
        let isRecordingSpy = ValueSpy(sut.isRecording())
        
        XCTAssertEqual(isRecordingSpy.values, [false])
    }
    
    func test_init_doesNotMessagePlayer() {
        
        let (_, player, _) = makeSUT()
        
        XCTAssertTrue(player.messages.isEmpty)
    }
    
    func test_init_doesNotMessageRecorder() {
        
        let (_, _, recorder) = makeSUT()
        
        XCTAssertTrue(recorder.messages.isEmpty)
    }
    
    func test_addLayerForInstrumentWithSample_addsLayerWithCorrectPropertiesAndIncrementingNumber() {
        
        let (sut, _, _) = makeSUT()
        
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
        
        let (sut, _, _) = makeSUT()
        
        let firstLayerID = UUID()
        sut.addLayer(id: firstLayerID, for: .guitar, with: someSample())
        XCTAssertEqual(sut.active, firstLayerID)
        
        let secondLayerID = UUID()
        sut.addLayer(id: secondLayerID, for: .guitar, with: someSample())
        XCTAssertEqual(sut.active, secondLayerID)
    }
    
    func test_addLayerForRecording_addsLayerWithCorrectPropertiesAndIncrementingNumber() {
        
        let (sut, _, _) = makeSUT()
        
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
        
        let (sut, _, _) = makeSUT()
        
        let firstLayerID = UUID()
        sut.addLayer(id: firstLayerID, forRecording: someRecordingData())
        XCTAssertEqual(sut.active, firstLayerID)
        
        let secondLayerID = UUID()
        sut.addLayer(id: secondLayerID, forRecording: someRecordingData())
        XCTAssertEqual(sut.active, secondLayerID)
    }
    
    func test_setIsPlayingForLayerID_updatesLayersIsPlayingState(){
        
        let (sut, _, _) = makeSUT()
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
        
        let (sut, player, _) = makeSUT()
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
        
        let (sut, _, _) = makeSUT()
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
        
        let (sut, player, _) = makeSUT()
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
        
        let (sut, _, _) = makeSUT()
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
        
        let (sut, _, _) = makeSUT()
        sut.addLayer(for: .guitar, with: someSample())
        XCTAssertEqual(sut.active, sut.layers.first?.id)
        
        sut.delete(layerID: sut.layers.first!.id)
        
        XCTAssertNil(sut.active)
    }
    func test_deleteLayerID_setActiveToLastLayerIDOnDeleteActiveLayerAndLayersRemain() {
        
        let (sut, _, _) = makeSUT()
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
        
        let (sut, _, _) = makeSUT()
        sut.addLayer(for: .guitar, with: someSample())
        sut.addLayer(for: .drums, with: someSample())
        sut.addLayer(forRecording: someRecordingData())
        let activeLayerID = sut.layers[2].id
        XCTAssertEqual(sut.active, activeLayerID)
        
        sut.delete(layerID: sut.layers.first!.id)
        
        XCTAssertEqual(sut.active, activeLayerID)
    }
    
    func test_deleteLayerID_messagesPlayerToStopPlayLayerWithID() {
        
        let (sut, player, _) = makeSUT()
        let layerID = UUID()
        sut.addLayer(id: layerID, for: .guitar, with: someSample())
        sut.set(isPlayingAll: true)
        
        sut.delete(layerID: layerID)
        
        XCTAssertEqual(player.messages.last, .stop(layerID))
    }
    
    func test_selectLayerID_doNothingOnIncorrectID() {
        
        let (sut, _, _) = makeSUT()
        sut.addLayer(for: .guitar, with: someSample())
        sut.addLayer(for: .drums, with: someSample())
        sut.addLayer(forRecording: someRecordingData())
        
        sut.select(layerID: UUID())
        
        XCTAssertEqual(sut.active, sut.layers[2].id)
    }
    
    func test_selectLayerID_updatesActiveLayerForCorrectLayerID() {
        
        let (sut, _, _) = makeSUT()
        sut.addLayer(for: .guitar, with: someSample())
        sut.addLayer(for: .drums, with: someSample())
        sut.addLayer(forRecording: someRecordingData())
        
        sut.select(layerID: sut.layers[0].id)
        
        XCTAssertEqual(sut.active, sut.layers[0].id)
    }
    
    func test_startRecording_messagesRecorder() {
        
        let (sut, _, recorder) = makeSUT()
        
        sut.startRecording()
        
        XCTAssertEqual(recorder.messages, [.startRecording])
    }
    
    func test_startRecording_setIsRecordingToFalseAndMessageDelegateOnFailure() {
        
        let sut = Producer(player: PlayerSpy(), recorder: AlwaysFailingRecorderStub())
        let isRecordingSpy = ValueSpy(sut.isRecording())
        let delegateSpy = ValueSpy(sut.delegateActionSubject)
        
        sut.startRecording()
        
        XCTAssertEqual(isRecordingSpy.values, [false])
        XCTAssertEqual(delegateSpy.values, [.recordingFailed])
    }
    
    func test_startRecording_setIsRecodingToTrueOnSuccess() {
        
        let (sut, _, _) = makeSUT()        
        let isRecordingSpy = ValueSpy(sut.isRecording())

        sut.startRecording()
        
        XCTAssertEqual(isRecordingSpy.values, [false, true])
    }
    
    func test_stopRecording_messagesRecorder() {
        
        let (sut, _, recorder) = makeSUT()
        
        sut.stopRecording()
        
        XCTAssertEqual(recorder.messages, [.stopRecoding])
    }
    
    func test_stopRecording_isRecordingBecomeFalseAndInformDelegate() {
        
        let (sut, _, recorder) = makeSUT()
        let isRecordingSpy = ValueSpy(sut.isRecording())
        let delegateSpy = ValueSpy(sut.delegateActionSubject)
        sut.startRecording()
        
        sut.stopRecording()
        recorder.recodingSubject.send(completion: .failure(anyNSError()))
        
        XCTAssertEqual(isRecordingSpy.values, [false, true, false])
        XCTAssertEqual(delegateSpy.values, [.recordingFailed])
    }
    
    func test_stopRecording_addNewRecordingLayerOnSuccess() {
        
        let (sut, player, recorder) = makeSUT()
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
        
        let (sut, player, _) = makeSUT()
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
        
        let (sut, _, _) = makeSUT()
        sut.addLayer(forRecording: someRecordingData())
        let initialControl = sut.layers[0].control
        
        let updatedControl = Layer.Control(volume: 0, speed: 0)
        XCTAssertNotEqual(initialControl, updatedControl)
        
        sut.setActiveLayer(control: updatedControl)
        XCTAssertEqual(sut.layers[0].control, updatedControl)
    }
    
    func test_setActiveLayerControl_messagesPlayerWithUpdateForLayerIDWithControl() {
        
        let (sut, player, _) = makeSUT()
        let layerID = UUID()
        let recordingData = Data("recording".utf8)
        sut.addLayer(id: layerID, forRecording: recordingData)
        
        let updatedControl = Layer.Control(volume: 1, speed: 1)
        sut.setActiveLayer(control: updatedControl)
        XCTAssertEqual(player.messages, [.update(layerID, updatedControl)])
    }
    
    func test_setIsPlayingForLayerID_firesPlayingProgressOnStartPlaying(){
        
        let (sut, player, _) = makeSUT()
        let layerID = Layer.ID()
        sut.addLayer(id: layerID, for: .guitar, with: someSample())
        
        let exp = expectation(description: "Wait for first timer value")
        playingProgressBinding = sut.playingProgress
            .print("SUB")
            .sink { progress in
                
                if progress > 0 {
                    exp.fulfill()
                    self.playingProgressBinding = nil
                }
            }
        
        sut.set(isPlaying: true, for: layerID)
        player.sendPlaying(event: 5)
        
        wait(for: [exp], timeout: 0.5)
    }
    
    //MARK: - Helpers
    
    private func makeSUT
    (
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> (
        sut: Producer,
        player: PlayerSpy,
        recorderSpy: RecorderSpy
    ) {
        
        let player = PlayerSpy()
        let recorder = RecorderSpy()
        let sut = Producer(player: player, recorder: recorder)
        trackForMemoryLeaks(player, file: file, line: line)
        trackForMemoryLeaks(recorder, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        
        return (sut, player, recorder)
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
    
    private func someSample() -> Sample {
        
        .init(id: UUID().uuidString, data: Data(UUID().uuidString.utf8))
    }
    
    private func someRecordingData() -> Data {
        
        Data(UUID().uuidString.utf8)
    }
    
    private func anyNSError() -> NSError {
        
        NSError(domain: "", code: 0)
    }
}
