//
//  ProducerTests.swift
//  
//
//  Created by Max Gribov on 31.10.2023.
//

import XCTest
import Combine
import Samples
import Producer

protocol Player {
    
    var playing: Set<Layer.ID> { get }
    func play(id: Layer.ID, data: Data, control: Layer.Control)
    func stop(id: Layer.ID)
}

final class Producer {
    
    @Published private(set) var layers: [Layer]
    @Published private(set) var active: Layer.ID?
    private var payloads: [Layer.ID: Payload]
    private let player: Player
    private var cancellable: AnyCancellable?
    
    init(player: Player) {
        
        self.layers = []
        self.active = nil
        self.payloads = [:]
        self.player = player
        
        cancellable = $layers
            .sink { [unowned self] layers in handleUpdate(layers: layers) }
    }
    
    func addLayer(id: UUID = UUID(), for instrument: Instrument, with sample: Sample) {
        
        let layer = Layer(id: id, name: sampleLayerName(for: instrument), isPlaying: false, isMuted: false, control: .initial)
        payloads[layer.id] = .sample(instrument, sample)
        layers.append(layer)
        active = layer.id
    }
    
    func addLayer(id: UUID = UUID(), forRecording data: Data) {
        
        let layer = Layer(id: id, name: recordingLayerName(), isPlaying: false, isMuted: false, control: .initial)
        payloads[layer.id] = .recording(data)
        layers.append(layer)
        active = layer.id
    }
    
    func set(isPlaying: Bool, for layerID: Layer.ID) {
        
        var updated = [Layer]()
        
        for layer in layers {
            
            if layer.id == layerID {
                
                var updatedLayer = layer
                updatedLayer.isPlaying = isPlaying
                updated.append(updatedLayer)
                
            } else if isPlaying == true, layer.isPlaying == true {
                
                var updatedLayer = layer
                updatedLayer.isPlaying = false
                updated.append(updatedLayer)
                
            } else {
                
                updated.append(layer)
            }
        }
        
        layers = updated
    }
    
    func set(isMuted: Bool, for layerID: Layer.ID) {
        
        var updated = [Layer]()
        
        for layer in layers {
            
            if layer.id == layerID {
                
                var updatedLayer = layer
                updatedLayer.isMuted = isMuted
                updated.append(updatedLayer)
                
            } else {
                
                updated.append(layer)
            }
        }
        
        layers = updated
    }
    
    func delete(layerID: Layer.ID) {
        
        layers = layers.filter { $0.id != layerID }
        payloads.removeValue(forKey: layerID)
    }
    
    func select(layerID: Layer.ID) {
        
        guard layers.map(\.id).contains(layerID) else {
            return
        }
        
        active = layerID
    }
    
    private func handleUpdate(layers: [Layer]) {
        
        let layersShouldPlay = layers.filter(\.isPlaying)
        
        for layerID in player.playing {
            
            guard layersShouldPlay.map(\.id).contains(layerID) == false else {
                continue
            }
            
            player.stop(id: layerID)
        }
        
        for layer in layersShouldPlay {
            
            guard player.playing.contains(layer.id) == false,
                  let soundData = payloads[layer.id]?.soundData else {
                
                continue
            }
            
            player.play(id: layer.id, data: soundData, control: layer.control)
        }
    }
    
    private func sampleLayerName(for instrument: Instrument) -> String {
        
        let currentLayersCount = payloads.values.compactMap(\.instrument).filter { $0 == instrument }.count
        
        return "\(instrument.name) \(currentLayersCount + 1)"
    }
    
    private func recordingLayerName() -> String {
        
        let currentLayersCount = payloads.values.map(\.isRecording).filter { $0 }.count
        
        //TODO: localisation required
        return "Запись \(currentLayersCount + 1)"
    }
}

extension Producer {
    
    enum Payload {
        
        case sample(Instrument, Sample)
        case recording(Data)
        
        var instrument: Instrument? {
            
            guard case let .sample(instrument, _) = self else {
                return nil
            }
            
            return instrument
        }
        
        var isRecording: Bool {
            
            switch self {
            case .recording: return true
            default: return false
            }
        }
        
        var soundData: Data {
            
            switch self {
            case .sample(_, let sample):
                return sample.data
                
            case .recording(let data):
                return data
            }
        }
    }
}

final class ProducerTests: XCTestCase {
    
    func test_init_emptyLayers() {
        
        let (sut, _) = makeSUT()
        
        XCTAssertTrue(sut.layers.isEmpty)
    }
    
    func test_init_activeLayerIsNil() {
        
        let (sut, _) = makeSUT()
        
        XCTAssertNil(sut.active)
    }
    
    func test_init_doesNotMessagePlayer() {
        
        let (_, player) = makeSUT()
        
        XCTAssertTrue(player.messages.isEmpty)
    }
    
    func test_addLayerForInstrumentWithSample_addsLayerWithCorrectPropertiesAndIncrementingNumber() {
        
        let (sut, _) = makeSUT()
        
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
        
        let (sut, _) = makeSUT()
        
        let firstLayerID = UUID()
        sut.addLayer(id: firstLayerID, for: .guitar, with: someSample())
        XCTAssertEqual(sut.active, firstLayerID)
        
        let secondLayerID = UUID()
        sut.addLayer(id: secondLayerID, for: .guitar, with: someSample())
        XCTAssertEqual(sut.active, secondLayerID)
    }
    
    func test_addLayerForRecording_addsLayerWithCorrectPropertiesAndIncrementingNumber() {
        
        let (sut, _) = makeSUT()
        
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
        
        let (sut, _) = makeSUT()
        
        let firstLayerID = UUID()
        sut.addLayer(id: firstLayerID, forRecording: someRecordingData())
        XCTAssertEqual(sut.active, firstLayerID)
        
        let secondLayerID = UUID()
        sut.addLayer(id: secondLayerID, forRecording: someRecordingData())
        XCTAssertEqual(sut.active, secondLayerID)
    }
    
    func test_setIsPlayingForLayerID_updatesLayersIsPlayingState(){
        
        let (sut, _) = makeSUT()
        sut.addLayer(for: .guitar, with: someSample())
        sut.addLayer(for: .drums, with: someSample())
        sut.addLayer(forRecording: someRecordingData())
        
        sut.set(isPlaying: true, for: sut.layers[0].id)
        XCTAssertEqual(sut.layers.map(\.isPlaying), [true, false, false])
        
        sut.set(isPlaying: true, for: sut.layers[1].id)
        XCTAssertEqual(sut.layers.map(\.isPlaying), [false, true, false])
        
        sut.set(isPlaying: false, for: sut.layers[1].id)
        XCTAssertEqual(sut.layers.map(\.isPlaying), [false, false, false])
    }
    
    func test_setIsPlayingForLayerID_messagesPlayerWithPlayAndStopCommands() {
        
        let (sut, player) = makeSUT()
        let guitarSample = someSample()
        sut.addLayer(for: .guitar, with: guitarSample)
        let drumsSample = someSample()
        sut.addLayer(for: .drums, with: drumsSample)
        sut.addLayer(forRecording: someRecordingData())
        
        sut.set(isPlaying: true, for: sut.layers[0].id)
        XCTAssertEqual(player.messages, [.play(sut.layers[0].id, guitarSample.data, sut.layers[0].control)])
        
        sut.set(isPlaying: true, for: sut.layers[1].id)
        XCTAssertEqual(player.messages, [.play(sut.layers[0].id, guitarSample.data, sut.layers[0].control),
                                         .stop(sut.layers[0].id),
                                         .play(sut.layers[1].id, drumsSample.data, sut.layers[1].control)])
        
        sut.set(isPlaying: false, for: sut.layers[1].id)
        XCTAssertEqual(player.messages, [.play(sut.layers[0].id, guitarSample.data, sut.layers[0].control),
                                         .stop(sut.layers[0].id),
                                         .play(sut.layers[1].id, drumsSample.data, sut.layers[1].control),
                                         .stop(sut.layers[1].id)])
    }
    
    func test_setIsMutedForLayerID_updateLayerState() {
        
        let (sut, _) = makeSUT()
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
    
    func test_deleteLayerID_removesLayerForID() {
        
        let (sut, _) = makeSUT()
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
    
    func test_selectLayerID_doNothingOnIncorrectID() {
        
        let (sut, _) = makeSUT()
        sut.addLayer(for: .guitar, with: someSample())
        sut.addLayer(for: .drums, with: someSample())
        sut.addLayer(forRecording: someRecordingData())
        
        sut.select(layerID: UUID())
        
        XCTAssertEqual(sut.active, sut.layers[2].id)
    }
    
    func test_selectLayerID_updatesActiveLayerForCorrectLayerID() {
        
        let (sut, _) = makeSUT()
        sut.addLayer(for: .guitar, with: someSample())
        sut.addLayer(for: .drums, with: someSample())
        sut.addLayer(forRecording: someRecordingData())
        
        sut.select(layerID: sut.layers[0].id)
        
        XCTAssertEqual(sut.active, sut.layers[0].id)
    }
    
    //MARK: - Helpers
    
    private func makeSUT() -> (sut: Producer, player: PlayerSpy) {
        
        let player = PlayerSpy()
        let sut = Producer(player: player)
        
        return (sut, player)
    }
    
    class PlayerSpy: Player {
        
        private (set) var playing = Set<Layer.ID>()
        var messages = [Message]()
        
        enum Message: Equatable {
            case play(Layer.ID, Data, Layer.Control)
            case stop(Layer.ID)
        }
        
        func play(id: Layer.ID, data: Data, control: Layer.Control) {
            
            messages.append(.play(id, data, control))
            playing.insert(id)
        }
        
        func stop(id: Layer.ID) {
            
            messages.append(.stop(id))
            playing.remove(id)
        }
    }
    
    private func someSample() -> Sample {
        .init(id: UUID().uuidString, data: Data(UUID().uuidString.utf8))
    }
    
    private func someRecordingData() -> Data {
        Data(UUID().uuidString.utf8)
    }
    
}
