//
//  SamplesLoaderTests.swift
//  
//
//  Created by Max Gribov on 30.10.2023.
//

import XCTest

final class SamplesLoader {
    
    private let store: SamplesLoaderTests.SamplesLocalStoreSpy
    
    init(store: SamplesLoaderTests.SamplesLocalStoreSpy) {
        
        self.store = store
    }
    
    func load(for instrument: Instrument, completion: @escaping (Result<Void, Error>) -> Void) {
        
        store.retrieveSamples(for: instrument, completion: completion)
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
        
        sut.load(for: .guitar) { _ in }
        
        XCTAssertEqual(store.receivedRequests, [.retrieveSamplesFor(.guitar)])
    }
    
    func test_load_failsOnRetrieveFail() {
        
        let (sut, store) = makeSUT()
        
        var receivedError: Error?
        sut.load(for: .guitar) { result in
            switch result {
            case let .failure(error):
                receivedError = error
                
            default:
                break
            }
        }
        
        store.complete(with: anyNSError())
        
        XCTAssertEqual(receivedError as? NSError, anyNSError())
    }
    
    //MARK: - Helpers
    
    private func makeSUT() -> (sut: SamplesLoader, store: SamplesLocalStoreSpy) {
        
        let store = SamplesLocalStoreSpy()
        let sut = SamplesLoader(store: store)
        
        return (sut, store)
    }
    
    final class SamplesLocalStoreSpy {
        
        enum Request: Equatable {
            case retrieveSamplesFor(Instrument)
        }
        
        private var completions = [(request: Request, completion: (Result<Void, Error>) -> Void)]()
        
        var receivedRequests: [Request] {
            completions.map(\.request)
        }
        
        func retrieveSamples(for instrument: Instrument, completion: @escaping (Result<Void, Error>) -> Void) {
            completions.append((.retrieveSamplesFor(instrument), completion))
        }
        
        func complete(with error: Error, at index: Int = 0) {
            completions[index].completion(.failure(error))
        }
    }
    
    private func anyNSError() -> NSError {
        .init(domain: "", code: 0)
    }
}
