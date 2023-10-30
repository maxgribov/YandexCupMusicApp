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
        
        let sut = makeSUT(bundle: invalidBundle())
        
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
        
        let sut = makeSUT(bundle: invalidBundle())
        
        expect(sut, retrieveSamplesIDsResult: .failure(BundleSamplesLocalStore.Error.unableRetrieveResourcePathForBundle), for: .brass)
    }

    func test_retrieveSamplesIDs_deliversGuitarFilesNamesAsIDsForGuitarInstrument() throws {
        
        let sut = makeSUT()
        let expected = try fileNames(bundle: BundleSamplesLocalStore.moduleBundle, prefix: "guitar")
        
        expect(sut, retrieveSamplesIDsResult: .success(expected), for: .guitar)
    }
    
    func test_retrieveSamplesIDs_deliversDrumsFilesNamesAsIDsForDrumsInstrument() throws {
        
        let sut = makeSUT()
        let expected = try fileNames(bundle: BundleSamplesLocalStore.moduleBundle, prefix: "drums")
        
        expect(sut, retrieveSamplesIDsResult: .success(expected), for: .drums)
    }
    
    func test_retrieveSamplesIDs_deliversBrassFilesNamesAsIDsForBrassInstrument() throws {
        
        let sut = makeSUT()
        let expected = try fileNames(bundle: BundleSamplesLocalStore.moduleBundle, prefix: "brass")
        
        expect(sut, retrieveSamplesIDsResult: .success(expected), for: .brass)
    }
    
    func test_retrieveSample_failsForResourcePathRetrievalError() {
        
        let sut = makeSUT(bundle: invalidBundle())
        
        expect(sut, retrieveSample: .failure(BundleSamplesLocalStore.Error.unableRetrieveResourcePathForBundle), for: anySampleID())
    }
    
    func test_retrieveSample_failsForNotExistingFileForSampleID() {
        
        let sut = makeSUT()
        
        expect(sut, retrieveSample: .failure(BundleSamplesLocalStore.Error.retrieveSampleFileFailed), for: notExistingSampleID())
    }
    
    //MARK: - Helpers
    
    private func makeSUT(bundle: Bundle? = nil) -> BundleSamplesLocalStore {
        
        let sut = BundleSamplesLocalStore(bundle: bundle)
        trackForMemoryLeaks(sut)
        
        return sut
    }
    
    private func expect(
        _ sut: BundleSamplesLocalStore,
        retrieveSamplesIDsResult expectedResult: Result<[SampleID], Error>,
        for instrument: Instrument,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        
        let exp = expectation(description: "Wait for completion")
        sut.retrieveSamplesIDs(for: instrument) { receivedResult in
            
            switch (receivedResult, expectedResult) {
            case let (.success(receivedIds), .success(expectedIds)):
                XCTAssertEqual(receivedIds, expectedIds, "Expected IDs: \(expectedIds), got \(receivedIds) instead", file: file, line: line)
                
            case let (.failure(receivedError), .failure(expectedError)):
                XCTAssertEqual(receivedError as NSError, expectedError as NSError, "Expected error: \(expectedError), got \(receivedError) instead", file: file, line: line)
                
            default:
                XCTFail("Expected result: \(expectedResult), got \(receivedResult) instead", file: file, line: line)
            }
            
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: 1.0)
    }
    
    private func expect(
        _ sut: BundleSamplesLocalStore,
        retrieveSample expectedResult: Result<Sample, Error>,
        for sampleID: SampleID,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        
        let exp = expectation(description: "Wait for completion")
        sut.retrieveSample(for: sampleID) { receivedResult in
            
            switch (receivedResult, expectedResult) {
            case let (.success(receivedIds), .success(expectedIds)):
                XCTAssertEqual(receivedIds, expectedIds, "Expected IDs: \(expectedIds), got \(receivedIds) instead", file: file, line: line)
                
            case let (.failure(receivedError), .failure(expectedError)):
                XCTAssertEqual(receivedError as NSError, expectedError as NSError, "Expected error: \(expectedError), got \(receivedError) instead", file: file, line: line)
                
            default:
                XCTFail("Expected result: \(expectedResult), got \(receivedResult) instead", file: file, line: line)
            }
            
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: 1.0)
    }
    
    private func fileNames(bundle: Bundle, prefix: String) throws -> [String] {
        
        guard let path = bundle.resourcePath else {
            throw NSError(domain: "BundleSamplesLocalStoreTestsError", code: 1)
        }
        
        return try FileManager.default.contentsOfDirectory(atPath: path)
            .filter { $0.hasPrefix(prefix) }
    }
    
    private func invalidBundle() -> Bundle {
        Bundle()
    }
    
    private func anySampleID() -> SampleID {
        "any-sample-file-name"
    }
    
    private func notExistingSampleID() -> SampleID {
        "Sample file not exists"
    }
}
