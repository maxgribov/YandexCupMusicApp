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

final class Producer {
    
    @Published private(set) var layers: [Layer]
    private var payloads: [Layer.ID: Payload]
    
    init(player: ProducerTests.PlayerSpy) {
        
        self.layers = []
        self.payloads = [:]
    }
    
    func addLayer(id: UUID = UUID(), for instrument: Instrument, with sample: Sample) {
        
        let layer = Layer(id: id, name: sampleLayerName(for: instrument), isPlaying: false, isMuted: false, control: .initial)
        payloads[layer.id] = .sample(instrument, sample)
        layers.append(layer)
    }
    
    private func sampleLayerName(for instrument: Instrument) -> String {
        
        let currentLayersCount = payloads.values.compactMap(\.instrument).filter { $0 == instrument }.count
        
        return "\(instrument.name) \(currentLayersCount + 1)"
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
    }
}

final class ProducerTests: XCTestCase {
    
    func test_init_emptyLayers() {
        
        let (sut, _) = makeSUT()
        
        XCTAssertTrue(sut.layers.isEmpty)
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
    

    
    private func makeSUT() -> (sut: Producer, player: PlayerSpy) {
        
        let player = PlayerSpy()
        let sut = Producer(player: player)
        
        return (sut, player)
    }
    
    class PlayerSpy {
        
        var messages = [Any]()
    }
    
    private func someSample() -> Sample {
        .init(id: UUID().uuidString, data: Data(UUID().uuidString.utf8))
    }
    
}
