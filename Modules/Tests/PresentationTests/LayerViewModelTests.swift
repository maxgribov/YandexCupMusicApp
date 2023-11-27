//
//  LayerViewModelTests.swift
//
//
//  Created by Max Gribov on 31.10.2023.
//

import XCTest
import Combine
import Domain
import Presentation

final class LayerViewModelTests: XCTestCase {
    
    func test_initWitLayer_correctlySetup() {
        
        let layer = Layer(id: UUID(), name: "some layer", isPlaying: true, isMuted: false, control: .init(volume: 0, speed: 0))
        let sut = LayerViewModel(with: layer, isActive: true)
        
        XCTAssertEqual(sut.id, layer.id)
        XCTAssertEqual(sut.name, layer.name)
        XCTAssertEqual(sut.isPlaying, layer.isPlaying)
        XCTAssertEqual(sut.isMuted, layer.isMuted)
        XCTAssertEqual(sut.isActive, true)
    }
            
    //MARK: - Helpers
    
    private func makeSUT(id: Layer.ID = UUID(), name: String = "", isPlaying: Bool = false, isMuted: Bool = false, isActive: Bool = true) -> LayerViewModel {
        
        let sut = LayerViewModel(id: id, name: name, isPlaying: isPlaying, isMuted: isMuted, isActive: isActive)
        
        return sut
    }
}
