//
//  ProducerTests.swift
//  
//
//  Created by Max Gribov on 31.10.2023.
//

import XCTest
import Combine
import Producer

final class Producer {
    
    @Published private(set) var layers: [Layer]
    
    init() { self.layers = [] }
}

final class ProducerTests: XCTestCase {

    func test_init_emptyLayers() {
        
        let sut = Producer()
        
        XCTAssertTrue(sut.layers.isEmpty)
    }

}
