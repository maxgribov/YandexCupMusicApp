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
        
        let (_, store) = makeSUT()
        
        XCTAssertEqual(store.receivedRequests.count, 0)
    }
    
    func test_load_requestsSamplesRetrieval() {
        
        let (sut, store) = makeSUT()
        
        sut.load(for: .guitar)
        
        XCTAssertEqual(store.receivedRequests, [.retrieveSamplesFor(.guitar)])
    }
    
    //MARK: - Helpers
    
    private func makeSUT() -> (sut: SamplesLoader, store: SamplesStoreSpy) {
        
        let store = SamplesStoreSpy()
        let sut = SamplesLoader(store: store)
        
        return (sut, store)
    }
    
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
