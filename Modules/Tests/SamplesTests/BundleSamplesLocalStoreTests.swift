//
//  BundleSamplesLocalStoreTests.swift
//  
//
//  Created by Max Gribov on 30.10.2023.
//

import XCTest
import Samples

final class BundleSamplesLocalStoreTests: XCTestCase {

    func test_retrieve_deliversErrorForResourcePathRetrievalError() throws {
        
        let sut = BundleSamplesLocalStore(bundle: Bundle())
        
        var resultError: Error? = nil
        sut.retrieveSamples(for: .brass) { result in
            
            switch result {
            case let  .failure(error):
                resultError = error
                
            default:
                break
            }
        }
        
        XCTAssertEqual(resultError as? BundleSamplesLocalStore.Error, .unableRetrieveResourcePathForBundle)
    }
}
