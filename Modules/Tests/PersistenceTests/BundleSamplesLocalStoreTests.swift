//
//  BundleSamplesLocalStoreTests.swift
//  
//
//  Created by Max Gribov on 30.10.2023.
//

import XCTest
import Domain
import Persistence

final class BundleSamplesLocalStoreTests: XCTestCase {

    //MARK: - Sample IDs
    
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
    
    //MARK: - Sample
    
    func test_retrieveSample_failsForResourcePathRetrievalError() {
        
        let sut = makeSUT(bundle: invalidBundle())
        
        expect(sut, retrieveSample: .failure(BundleSamplesLocalStore.Error.unableRetrieveResourcePathForBundle), for: anySampleID())
    }
    
    func test_retrieveSample_failsForNotExistingFileForSampleID() {
        
        let sut = makeSUT()
        
        expect(sut, retrieveSample: .failure(BundleSamplesLocalStore.Error.retrieveSampleFileFailed), for: notExistingSampleID())
    }
    
    func test_retrieveSample_deliversSampleExistingFileForSampleID() throws {
        
        let sut = makeSUT()
        let expectedFile = try firstFile(bundle: BundleSamplesLocalStore.moduleBundle, prefix: "guitar")
        
        expect(sut, retrieveSample: .success(Sample(id: expectedFile.name, data: expectedFile.data)), for: expectedFile.name)
    }
    
    //MARK: - Helpers
    
    private func makeSUT(
        bundle: Bundle? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> BundleSamplesLocalStore {
        
        let sut = BundleSamplesLocalStore(bundle: bundle)
        trackForMemoryLeaks(sut, file: file, line: line)
        
        return sut
    }
    
    private func expect(
        _ sut: BundleSamplesLocalStore,
        retrieveSamplesIDsResult expectedResult: Result<[Sample.ID], Error>,
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
        for sampleID: Sample.ID,
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
    
    private func firstFile(bundle: Bundle, prefix: String) throws -> (name: String, data: Data) {
        
        let fileNames = try fileNames(bundle: bundle, prefix: prefix)
        guard let firstFileName = fileNames.first else {
            throw NSError(domain: "BundleSamplesLocalStoreTestsError", code: 2)
        }
        
        guard let path = bundle.resourcePath else {
            throw NSError(domain: "BundleSamplesLocalStoreTestsError", code: 1)
        }
        let filePath = path + "/" + firstFileName
        let url = URL(filePath: filePath)
        let data = try Data(contentsOf: url)
        
        return (firstFileName, data)
    }
    
    private func invalidBundle() -> Bundle {
        Bundle()
    }
    
    private func anySampleID() -> Sample.ID {
        "any-sample-file-name"
    }
    
    private func notExistingSampleID() -> Sample.ID {
        "Sample file not exists"
    }
}