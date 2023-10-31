//
//  SampleSelectorViewModelTests.swift
//
//
//  Created by Max Gribov on 31.10.2023.
//

import XCTest
import Samples
import Combine

final class SampleSelectorViewModel {
    
    let items: [SampleItemViewModel]
    let delegateActionSubject = PassthroughSubject<DelegateAction, Never>()
    
    private let loadSample: () -> AnyPublisher<Sample, Error>
    private var cancellable: AnyCancellable?
    
    init(items: [SampleItemViewModel], loadSample: @escaping () -> AnyPublisher<Sample, Error>) {
        
        self.items = items
        self.loadSample = loadSample
    }
    
    func itemDidSelected(for itemID: SampleItemViewModel.ID) {
        
        guard let item = items.first(where: { $0.id == itemID }) else {
            return
        }
        
        cancellable = loadSample()
            .sink(receiveCompletion: { [weak self] completion in
                
                switch completion {
                case .failure:
                    self?.delegateActionSubject.send(.failedSelectSample(itemID))
                    
                case .finished:
                    break
                }
                
            }, receiveValue: { sample in
                
            })
    }
}

extension SampleSelectorViewModel {
    
    enum DelegateAction: Equatable {
        
        case sampleDidSelected(Sample)
        case failedSelectSample(SampleID)
    }
}

struct SampleItemViewModel: Identifiable, Equatable {
    
    let id: SampleID
    let name: String
}

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
        let sut = makeSUT(loadSample: { loadSampleSpy })
        
        sut.itemDidSelected(for: sut.items[0].id)
        XCTWaiter().wait(for: [], timeout: 0.01)
        
        XCTAssertTrue(isSubscribed)
    }
    
    func test_itemDidSelected_informDelegateSampleSelectionFailForSampleLoadingError() {
        
        let loadSampleStub = PassthroughSubject<Sample, Error>()
        let sut = makeSUT(loadSample: { loadSampleStub.eraseToAnyPublisher() })
        
        let selectedItem = sut.items[0]
        sut.itemDidSelected(for: selectedItem.id)
        XCTWaiter().wait(for: [], timeout: 0.01)
        
        expect(sut, delegateAction: .failedSelectSample(selectedItem.id), for: {
            
            loadSampleStub.send(completion: .failure(anyNSError()))
        })
    }
    
    //MARK: - Helpers
    
    private func makeSUT(
        items: [SampleItemViewModel] = SampleSelectorViewModelTests.sampleItems(),
        loadSample: @escaping () -> AnyPublisher<Sample, Error> = SampleSelectorViewModelTests.loadSampleDummy,
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
        
        var receivedDelegateAction: SampleSelectorViewModel.DelegateAction? = nil
        sut.delegateActionSubject
            .sink { receivedDelegateAction = $0 }
            .store(in: &cancellables)
        
        action()
        
        XCTWaiter().wait(for: [], timeout: 0.01)
        
        XCTAssertEqual(receivedDelegateAction, expectedDelegateAction, "Expected \(String(describing: expectedDelegateAction)), got \(String(describing: receivedDelegateAction)) instead", file: file, line: line)
    }
    
    private static func sampleItems() -> [SampleItemViewModel] {
        
        [.init(id: "1", name: "sample 1"),
         .init(id: "2", name: "sample 2"),
         .init(id: "3", name: "sample 3")]
    }
    
    private func wrongItemID() -> SampleItemViewModel.ID {
        "wrong item id"
    }
    
    private static func loadSampleDummy() -> AnyPublisher<Sample, Error> {
        
        Just(Sample(id: "", data: Data()))
            .mapError{ _ in NSError(domain: "", code: 0) }
            .eraseToAnyPublisher()
    }
    
    private func anyNSError() -> NSError {
        
        NSError(domain: "", code: 0)
    }
}
