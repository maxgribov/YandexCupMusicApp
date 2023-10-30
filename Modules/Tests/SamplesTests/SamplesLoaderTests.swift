//
//  SamplesLoaderTests.swift
//  
//
//  Created by Max Gribov on 30.10.2023.
//

import XCTest
import Samples

final class SamplesLoaderTests: XCTestCase {

    func test_init_doesNotRequestData() {
        
        let (_, store) = makeSUT()
        
        XCTAssertEqual(store.receivedRequests.count, 0)
    }
    
    func test_load_requestsSamplesRetrieval() {
        
        let (sut, store) = makeSUT()
        
        sut.load(for: .guitar) { _ in }
        
        XCTAssertEqual(store.receivedRequests, [.retrieveSamplesFor(.guitar)])
    }
    
    func test_load_failsOnRetrieveFail() {
        
        let (sut, store) = makeSUT()
        
        expected(sut, result: .failure(anyNSError()), for: {
            
            store.complete(with: anyNSError())
        })
    }
    
    func test_load_deliversSamplesOnSuccessRetrieval() {
        
        let (sut, store) = makeSUT()
        
        expected(sut, result: .success(uniqueSamples()), for: {
            
            store.complete(with: uniqueSamples())
        })
    }
    
    func test_load_deliversEmptyOnEmptyRetrieval() {
        
        let (sut, store) = makeSUT()
        
        expected(sut, result: .success([]), for: {
            
            store.complete(with: [])
        })
    }
    
    func test_load_doesNotDeliverResultAfterSUTInstanceDeinit() {
        
        let store = SamplesLocalStoreSpy()
        var sut: SamplesLoader<SamplesLocalStoreSpy>? = .init(store: store)
        
        var receivedResult: Result<[Sample], Error>? = nil
        sut?.load(for: .brass) { receivedResult = $0 }
        sut = nil
        
        store.complete(with: uniqueSamples())
        
        XCTAssertNil(receivedResult)
    }
    
    //MARK: - Helpers
    
    private func makeSUT(
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> (
        sut: SamplesLoader<SamplesLocalStoreSpy>,
        store: SamplesLocalStoreSpy
        
    ) {
        
        let store = SamplesLocalStoreSpy()
        let sut = SamplesLoader(store: store)
        
        trackForMemoryLeaks(store, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        
        return (sut, store)
    }
    
    final class SamplesLocalStoreSpy: SamplesLocalStore {
        
        enum Request: Equatable {
            case retrieveSamplesFor(Instrument)
        }
        
        private var completions = [(request: Request, completion: (SamplesLocalStore.Result) -> Void)]()
        
        var receivedRequests: [Request] {
            completions.map(\.request)
        }
        
        func retrieveSamples(for instrument: Instrument, completion: @escaping (SamplesLocalStore.Result) -> Void) {
            completions.append((.retrieveSamplesFor(instrument), completion))
        }
        
        func complete(with error: Error, at index: Int = 0) {
            completions[index].completion(.failure(error))
        }
        
        func complete(with samples: [Sample], at index: Int = 0) {
            completions[index].completion(.success(samples))
        }
    }
    
    func expected(
        _ sut: SamplesLoader<SamplesLocalStoreSpy>,
        result expectedResult: SamplesLocalStore.Result,
        for action: () -> Void,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        
        let exp = expectation(description: "Waiting for completion")
        sut.load(for: .drums) { receivedResult in
            
            switch (receivedResult, expectedResult) {
            case let (.success(receivedSamples), .success(expectedSamples)):
                XCTAssertEqual(receivedSamples, expectedSamples, "Expected samples: \(expectedSamples), got \(receivedSamples) instead", file: file, line: line)
                
            case let (.failure(receivedError as NSError), .failure(expectedError as NSError)):
                XCTAssertEqual(receivedError, expectedError, "Expected error: \(expectedError), got \(receivedError) instead", file: file, line: line)
                
            default:
                XCTFail("Expected \(expectedResult), got \(receivedResult) instead", file: file, line: line)
            }
            
            exp.fulfill()
        }
        
        action()
        
        wait(for: [exp], timeout: 1.0)
    }
    
    private func anyNSError() -> NSError {
        .init(domain: "", code: 0)
    }
    
    private func uniqueSamples() -> [Sample] {
        [.init(name: "first", data: Data("first-data".utf8)),
         .init(name: "second", data: Data("second-data".utf8))]
    }
}
