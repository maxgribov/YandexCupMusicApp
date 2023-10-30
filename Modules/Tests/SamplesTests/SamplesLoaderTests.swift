//
//  SamplesLoaderTests.swift
//  
//
//  Created by Max Gribov on 30.10.2023.
//

import XCTest

final class SamplesLoader {
    
    private let store: SamplesLoaderTests.SamplesStoreSpy
    
    init(store: SamplesLoaderTests.SamplesStoreSpy) {
        
        self.store = store
    }
    
    func load(for instrument: Instrument) {
        
        store.retrieveSamples(for: instrument)
    }
}

enum Instrument {
    
    case guitar
    case drums
    case tube
}

final class SamplesLoaderTests: XCTestCase {

    func test_init_doesNotRequestData() {
        
        let store = SamplesStoreSpy()
        let _ = SamplesLoader(store: store)
        
        XCTAssertEqual(store.receivedRequests.count, 0)
    }
    
    func test_load_requestsSamplesRetrieval() {
        
        let store = SamplesStoreSpy()
        let sut = SamplesLoader(store: store)
        
        sut.load(for: .guitar)
        
        XCTAssertEqual(store.receivedRequests, [.retrieveSamplesFor(.guitar)])
    }
    
    //MARK: - Helpers
    
    final class SamplesStoreSpy {
        
        enum Request: Equatable {
            
            case retrieveSamplesFor(Instrument)
        }
        
        private(set) var receivedRequests = [Request]()
        
        func retrieveSamples(for instrument: Instrument) {
            receivedRequests.append(.retrieveSamplesFor(instrument))
        }
    }
}
