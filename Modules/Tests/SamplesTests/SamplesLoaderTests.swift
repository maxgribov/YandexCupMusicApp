//
//  SamplesLoaderTests.swift
//  
//
//  Created by Max Gribov on 30.10.2023.
//

import XCTest

final class SamplesLoader {
    
    init(store: SamplesLoaderTests.SamplesStoreSpy) {
        
    }
}

final class SamplesLoaderTests: XCTestCase {

    func test_init_doesNotRequestData() {
        
        let store = SamplesStoreSpy()
        let _ = SamplesLoader(store: store)
        
        XCTAssertEqual(store.receivedRequests.count, 0)
    }
    
    //MARK: - Helpers
    
    final class SamplesStoreSpy {
        
        var receivedRequests = [Any]()
    }
}
