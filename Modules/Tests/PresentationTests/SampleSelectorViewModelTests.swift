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
    
    init(items: [SampleItemViewModel]) {
        
        self.items = items
    }
    
    func itemDidSelected(for itemID: SampleItemViewModel.ID) {
        
        
    }
}

extension SampleSelectorViewModel {
    
    enum DelegateAction: Equatable {
        
        case sampleDidSelected(SampleID)
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
        let sut = SampleSelectorViewModel(items: items)
        
        XCTAssertEqual(sut.items, items)
    }
    
    func test_itemDidSelected_doesNotInformDelegateForWrongItemID() {
        
        let sut = SampleSelectorViewModel(items: sampleItems())
        
        expect(sut, delegateAction: nil, for: {
            
            sut.itemDidSelected(for: wrongItemID())
        })
    }
    
    //MARK: - Helpers
    
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
    
    private func sampleItems() -> [SampleItemViewModel] {
        
        [.init(id: "1", name: "sample 1"),
         .init(id: "2", name: "sample 2"),
         .init(id: "3", name: "sample 3")]
    }
    
    private func wrongItemID() -> SampleItemViewModel.ID {
        "wrong item id"
    }
}
