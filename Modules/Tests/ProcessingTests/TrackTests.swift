//
//  TrackTests.swift
//  
//
//  Created by Max Gribov on 29.11.2023.
//

import XCTest
import Processing
import Domain

final class TrackTests: XCTestCase {

    func test_initWithLayer_correctlyInitProperties() {
        
        let layer = Layer(id: anyLayerID(), name: "", isPlaying: false, isMuted: false, control: .init(volume: 1, speed: 1))
        let data = anyData()
        let sut = Track(with: layer, data: data)
        
        XCTAssertEqual(sut.id, layer.id)
        XCTAssertEqual(sut.data, data)
        XCTAssertEqual(sut.volume, Float(layer.control.volume), accuracy: .ulpOfOne)
        XCTAssertEqual(sut.rate, 2, accuracy: .ulpOfOne)
    }
}
