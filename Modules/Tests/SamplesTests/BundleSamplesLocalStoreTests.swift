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
    
    func test_retrieveSamplesIDs_deliversGuitarFilesNamesAsIDsForGuitarInstrument() throws {
        
        let sut = makeSUT()
        let expected = try fileNames(bundle: BundleSamplesLocalStore.moduleBundle, prefix: "guitar")
        
        let result = try sut.retrieveSamplesIDs(for: .guitar)
        
        XCTAssertEqual(result, expected)
    }
    
    func test_retrieveSamplesIDs_deliversDrumsFilesNamesAsIDsForDrumsInstrument() throws {
        
        let sut = makeSUT()
        let expected = try fileNames(bundle: BundleSamplesLocalStore.moduleBundle, prefix: "drums")
        
        let result = try sut.retrieveSamplesIDs(for: .drums)
        
        XCTAssertEqual(result, expected)
    }
    
    func test_retrieveSamplesIDs_deliversBrassFilesNamesAsIDsForBrassInstrument() throws {
        
        let sut = makeSUT()
        let expected = try fileNames(bundle: BundleSamplesLocalStore.moduleBundle, prefix: "brass")
        
        let result = try sut.retrieveSamplesIDs(for: .brass)
        
        XCTAssertEqual(result, expected)
    }
    
    //MARK: - Helpers
    
    private func makeSUT(bundle: Bundle? = nil) -> BundleSamplesLocalStore {
        
        let sut = BundleSamplesLocalStore(bundle: bundle)
        trackForMemoryLeaks(sut)
        
        return sut
    }
    
    private func fileNames(bundle: Bundle, prefix: String) throws -> [String] {
        
        guard let path = bundle.resourcePath else {
            throw NSError(domain: "BundleSamplesLocalStoreTestsError", code: 1)
        }
        
        return try FileManager.default.contentsOfDirectory(atPath: path)
            .filter { $0.hasPrefix(prefix) }
    }
}
