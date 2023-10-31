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
    
    init(player: ProducerTests.PlayerSpy) {
        
        self.layers = []
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
    
    private func makeSUT() -> (sut: Producer, player: PlayerSpy) {
        
        let player = PlayerSpy()
        let sut = Producer(player: player)
        
        return (sut, player)
    }
    
    class PlayerSpy {
        
        var messages = [Any]()
    }
}
