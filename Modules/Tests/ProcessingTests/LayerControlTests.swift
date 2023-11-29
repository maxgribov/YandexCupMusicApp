//
//  LayerControlTests.swift
//  
//
//  Created by Max Gribov on 29.11.2023.
//

import XCTest
import Processing
import Domain

final class LayerControlTests: XCTestCase {
    
    
    func test_rate_delivers_0_5_for_speed_0() {
        
        let sut = Layer.Control(volume: anyVolume(), speed: 0)
        
        XCTAssertEqual(sut.rate, 0.5, accuracy: .ulpOfOne)
    }
    
    func test_rate_delivers_2_for_speed_1() {
        
        let sut = Layer.Control(volume: anyVolume(), speed: 1)
        
        XCTAssertEqual(sut.rate, 2, accuracy: .ulpOfOne)
    }
    
    func test_rate_delivers_1_25_for_speed_0_5() {
        
        let sut = Layer.Control(volume: anyVolume(), speed: 0.5)
        
        XCTAssertEqual(sut.rate, 1.25, accuracy: .ulpOfOne)
    }
    
    func test_rate_delivers_1_01_for_speed_0_34() {
        
        let sut = Layer.Control(volume: anyVolume(), speed: 0.34)
        
        XCTAssertEqual(sut.rate, 1.01, accuracy: .ulpOfOne)
    }
    
    func test_rate_delivers_0_5_for_speed_minus_1() {
        
        let sut = Layer.Control(volume: anyVolume(), speed: -1)
        
        XCTAssertEqual(sut.rate, 0.5, accuracy: .ulpOfOne)
    }
    
    func test_rate_delivers_2_for_speed_10() {
        
        let sut = Layer.Control(volume: anyVolume(), speed: 10)
        
        XCTAssertEqual(sut.rate, 2, accuracy: .ulpOfOne)
    }
    
    private func anyVolume() -> Double {
        
        Double.random(in: 0...1)
    }
    
    private func anySpeed() -> Double {
        
        Double.random(in: 0...1)
    }
}
