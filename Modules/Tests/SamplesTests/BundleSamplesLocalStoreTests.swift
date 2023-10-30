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
        
        let sut = makeSUT(bundle: Bundle())
        
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
    
    func test_retrieveSamplesIDs_deliversErrorForResourcePathRetrievalError() {
        
        let sut = makeSUT(bundle: Bundle())
        
        XCTAssertThrowsError(try sut.retrieveSamplesIDs(for: .brass))
    }
    
    //MARK: - Helpers
    
    private func makeSUT(bundle: Bundle? = nil) -> BundleSamplesLocalStore {
        
        let sut = BundleSamplesLocalStore(bundle: bundle)
        trackForMemoryLeaks(sut)
        
        return sut
    }
}
