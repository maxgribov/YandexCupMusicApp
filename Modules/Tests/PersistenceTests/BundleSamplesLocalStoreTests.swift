//
//  BundleSamplesLocalStoreTests.swift
//  
//
//  Created by Max Gribov on 30.10.2023.
//

import XCTest
import Domain
import Persistence
import AVFoundation

final class BundleSamplesLocalStoreTests: XCTestCase {

    //MARK: - Sample IDs
    
    func test_retrieveSamplesIDs_deliversErrorForResourcePathRetrievalError() {
        
        let sut = makeSUT(bundle: invalidBundle())
        
        expect(sut, retrieveSamplesIDsResult: .failure(BundleSamplesLocalStore.Error.unableRetrieveResourcePathForBundle), for: .brass)
    }

    func test_retrieveSamplesIDs_deliversGuitarFilesNamesAsIDsForGuitarInstrument() throws {
        
        let sut = makeSUT()
        
        expect(sut, retrieveSamplesIDsResult: .success(try expectedFileNames(for: .guitar)), for: .guitar)
    }
    
    func test_retrieveSamplesIDs_deliversDrumsFilesNamesAsIDsForDrumsInstrument() throws {
        
        let sut = makeSUT()
        
        expect(sut, retrieveSamplesIDsResult: .success(try expectedFileNames(for: .drums)), for: .drums)
    }
    
    func test_retrieveSamplesIDs_deliversBrassFilesNamesAsIDsForBrassInstrument() throws {
        
        let sut = makeSUT()
        
        expect(sut, retrieveSamplesIDsResult: .success(try expectedFileNames(for: .brass)), for: .brass)
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
    
    func test_retrieveSample_deliversSampleExistingFileForSampleIDAndDefaultMapper() throws {
        
        let sut = makeSUT()
        let expectedFile = try expectedFirstFile(for: .guitar)
        
        expect(sut, retrieveSample: .success(Sample(id: expectedFile.name, data: expectedFile.data)), for: expectedFile.name)
    }
    
    func test_retrieveSample_deliversSampleExistingFileForSampleIDAndBufferMapper() throws {
        
        let sut = makeSUT(mapper: BundleSamplesLocalStore.bufferMapper(url:))
        let expectedSample = try expectedFirstSample(for: .guitar)
        
        expect(sut, retrieveSample: .success(expectedSample), for: expectedSample.id)
    }
    
    func test_bufferMapper_mapsSameURLIdenticalEachTime() throws {
        
        let sut = BundleSamplesLocalStore.bufferMapper(url:)
        let url = try firstFile(bundle: BundleSamplesLocalStore.moduleBundle, prefix: Instrument.guitar.fileNamePrefix)
        
        let firstResult = sut(url.url)
        let secondResult = sut(url.url)
        
        XCTAssertEqual(firstResult, secondResult)
    }
    
    //MARK: - Helpers
    
    private func makeSUT(
        bundle: Bundle? = nil,
        mapper: @escaping (URL) -> Data? = BundleSamplesLocalStore.basicMapper(url:),
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> BundleSamplesLocalStore {
        
        let sut = BundleSamplesLocalStore(bundle: bundle, mapper: mapper)
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
            case let (.success(receivedSample), .success(expectedSample)):
                XCTAssertEqual(receivedSample, expectedSample, "Expected Sample: \(expectedSample), got \(receivedSample) instead", file: file, line: line)
                
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
    
    private func firstFile(bundle: Bundle, prefix: String) throws -> (name: String, url: URL) {
        
        let fileNames = try fileNames(bundle: bundle, prefix: prefix)
        guard let firstFileName = fileNames.first else {
            throw NSError(domain: "BundleSamplesLocalStoreTestsError", code: 2)
        }
        
        guard let path = bundle.resourcePath else {
            throw NSError(domain: "BundleSamplesLocalStoreTestsError", code: 1)
        }
        let filePath = path + "/" + firstFileName
        let url = URL(filePath: filePath)
        
        return (firstFileName, url)
    }
    
    private func expectedFileNames(for instrument: Instrument) throws -> [String] {
        
        try fileNames(bundle: BundleSamplesLocalStore.moduleBundle, prefix: instrument.fileNamePrefix)
    }
    
    private func expectedFirstFile(for instrument: Instrument) throws -> (name: String, data: Data) {
        
        let file = try firstFile(bundle: BundleSamplesLocalStore.moduleBundle, prefix: instrument.fileNamePrefix)
        let data = try Data(contentsOf: file.url)
        
        return (file.name, data)
    }
    
    private func expectedFirstSample(for instrument: Instrument) throws -> Sample {
        
        let file = try firstFile(bundle: BundleSamplesLocalStore.moduleBundle, prefix: instrument.fileNamePrefix)
        
        guard let data = BundleSamplesLocalStore.bufferMapper(url: file.url) else {
            
            throw NSError(domain: "Expected First Sample for Instrument", code: 0)
        }
        
        return Sample(id: file.name, data: data)
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

private extension Instrument {
    
    var fileNamePrefix: String { rawValue }
}
