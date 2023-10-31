//
//  LayerViewModelTests.swift
//
//
//  Created by Max Gribov on 31.10.2023.
//

import XCTest

final class LayerViewModel: Identifiable {

    let id: Layer.ID
    let name: String
    @Published private(set) var isPlaying: Bool
    @Published private(set) var isMuted: Bool
    
    init(id: Layer.ID, name: String, isPlaying: Bool, isMuted: Bool) {
        
        self.id = id
        self.name = name
        self.isPlaying = isPlaying
        self.isMuted = isMuted
    }
    
    convenience init(with layer: Layer) {
        
        self.init(id: layer.id, name: layer.name, isPlaying: layer.isPlaying, isMuted: layer.isMuted)
    }
}

struct Layer {
    
    typealias ID = UUID
    
    let id: ID
    let name: String
    var isPlaying: Bool
    var isMuted: Bool
    var control: Control
    
    struct Control {
        
        let volume: Double
        let speed: Double
    }
}

final class LayerViewModelTests: XCTestCase {

    func test_initWitLayer_correctlySetup() {
        
        let layer = Layer(id: UUID(), name: "some layer", isPlaying: true, isMuted: false, control: .init(volume: 0, speed: 0))
        let sut = LayerViewModel(with: layer)
        
        XCTAssertEqual(sut.id, layer.id)
        XCTAssertEqual(sut.name, layer.name)
        XCTAssertEqual(sut.isPlaying, layer.isPlaying)
        XCTAssertEqual(sut.isMuted, layer.isMuted)
    }

}
