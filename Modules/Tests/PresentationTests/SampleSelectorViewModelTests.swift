//
//  SampleSelectorViewModelTests.swift
//
//
//  Created by Max Gribov on 31.10.2023.
//

import XCTest
import Domain
import Presentation
import Combine

final class SampleSelectorViewModelTests: XCTestCase {
    
    var cancellables = Set<AnyCancellable>()
    
    override func setUp() async throws {
        try await super.setUp()
        
        cancellables = []
    }

    func test_init_itemsConstructorInjected() {
        
        let items = [SampleItemViewModel(id: "1", name: "sample 1")]
        let sut = makeSUT(items: items)
        
        XCTAssertEqual(sut.items, items)
    }
    
    func test_init_isSampleLoadingFalse() {
        
        let sut = makeSUT()
        
        XCTAssertFalse(sut.isSampleLoading)
    }
    
    func test_itemDidSelected_doesNotInformDelegateForWrongItemID() {
        
        let sut = makeSUT()
        
        expect(sut, delegateAction: nil, for: {
            
            sut.itemDidSelected(for: wrongItemID())
        })
    }
    
    func test_itemDidSelected_startSampleLoadingForCorrectID() {
        
        var isSubscribed: Bool = false
        let loadSampleSpy = PassthroughSubject<Sample, Error>()
            .handleEvents(receiveSubscription: { _ in isSubscribed = true })
            .eraseToAnyPublisher()
        let sut = makeSUT(loadSample: { _ in loadSampleSpy })
        
        sut.itemDidSelected(for: sut.items[0].id)
        XCTWaiter().wait(for: [], timeout: 0.01)
        
        XCTAssertTrue(isSubscribed)
    }
    
    func test_itemDidSelected_informDelegateSampleSelectionFailForSampleLoadingError() {
        
        let loadSampleStub = PassthroughSubject<Sample, Error>()
        let sut = makeSUT(loadSample: { _ in loadSampleStub.eraseToAnyPublisher() })
        
        let selectedItem = sut.items[0]
        sut.itemDidSelected(for: selectedItem.id)
        XCTWaiter().wait(for: [], timeout: 0.01)
        
        expect(sut, delegateAction: .failedSelectSample(selectedItem.id), for: {
            
            loadSampleStub.send(completion: .failure(anyNSError()))
        })
    }
    
    func test_itemDidSelected_informDelegateSampleSelectionForSuccessSampleLoading() {
        
        let loadSampleStub = PassthroughSubject<Sample, Error>()
        let sut = makeSUT(loadSample: { _ in loadSampleStub.eraseToAnyPublisher() })
        
        let selectedItem = sut.items[0]
        sut.itemDidSelected(for: selectedItem.id)
        XCTWaiter().wait(for: [], timeout: 0.01)
        
        let loadedSample = anySample()
        expect(sut, delegateAction: .sampleDidSelected(loadedSample), for: {
            
            loadSampleStub.send(loadedSample)
        })
    }
    
    func test_isSampleLoading_falseOnWrongItemIDSelected() {
        
        let sut = makeSUT()
        
        sut.itemDidSelected(for: wrongItemID())
        
        XCTAssertFalse(sut.isSampleLoading)
    }
    
    func test_isSampleLoading_trueOnCorrectItemSelected() {
        
        let sut = makeSUT()
        
        sut.itemDidSelected(for: sut.items[0].id)
        
        XCTAssertTrue(sut.isSampleLoading)
    }
    
    func test_itemDidSelected_ignoreIfSampleAlreadyLoading() {
        
        var isCancelled: Bool = false
        let loadSampleSpy = PassthroughSubject<Sample, Error>()
            .handleEvents(receiveCancel: { isCancelled = true })
            .eraseToAnyPublisher()
        let sut = makeSUT(loadSample: { _ in loadSampleSpy })
        
        sut.itemDidSelected(for: sut.items[0].id)
        XCTWaiter().wait(for: [], timeout: 0.01)
        
        sut.itemDidSelected(for: sut.items[1].id)
        XCTWaiter().wait(for: [], timeout: 0.01)
        
        XCTAssertFalse(isCancelled)
    }
    
    //MARK: - Helpers
    
    private func makeSUT(
        items: [SampleItemViewModel] = SampleSelectorViewModelTests.sampleItems(),
        loadSample: @escaping (Sample.ID) -> AnyPublisher<Sample, Error> = SampleSelectorViewModelTests.loadSampleDummy,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> SampleSelectorViewModel {
        
        let sut = SampleSelectorViewModel(items: items, loadSample: loadSample)
        trackForMemoryLeaks(sut, file: file, line: line)
        
        return sut
    }
    
    private func expect(
        _ sut: SampleSelectorViewModel,
        delegateAction expectedDelegateAction: SampleSelectorViewModel.DelegateAction?,
        for action: () -> Void,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        
        let delegateSpy = ValueSpy(sut.delegateActionSubject)
        
        action()
        
        XCTWaiter().wait(for: [], timeout: 0.01)
        
        if let expectedDelegateAction {
            
            XCTAssertEqual(delegateSpy.values, [expectedDelegateAction], "Expected action: \(expectedDelegateAction), got \(delegateSpy.values) instead", file: file, line: line)
            
        } else {
            
            XCTAssertTrue(delegateSpy.values.isEmpty, "Expected no actions, got \(delegateSpy.values) instead", file: file, line: line)
        }
    }
    
    private static func sampleItems() -> [SampleItemViewModel] {
        
        [.init(id: "1", name: "sample 1"),
         .init(id: "2", name: "sample 2"),
         .init(id: "3", name: "sample 3")]
    }
    
    private func wrongItemID() -> SampleItemViewModel.ID {
        "wrong item id"
    }
    
    private static func loadSampleDummy(_ sampleID: Sample.ID) -> AnyPublisher<Sample, Error> {
        
        Just(Sample(id: "", data: Data()))
            .mapError{ _ in NSError(domain: "", code: 0) }
            .eraseToAnyPublisher()
    }
    
    private func anyNSError() -> NSError {
        
        NSError(domain: "", code: 0)
    }
    
    private func anySample() -> Sample {
        
        Sample(id: "123", data: Data("sample-data".utf8))
    }
}
