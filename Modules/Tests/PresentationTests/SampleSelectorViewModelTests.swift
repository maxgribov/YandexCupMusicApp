//
//  SampleSelectorViewModelTests.swift
//
//
//  Created by Max Gribov on 31.10.2023.
//

import XCTest
import Samples

final class SampleSelectorViewModel {
    
    let items: [SampleItemViewModel]
    
    init(items: [SampleItemViewModel]) {
        
        self.items = items
    }
}

struct SampleItemViewModel: Identifiable, Equatable {
    
    let id: SampleID
    let name: String
}

final class SampleSelectorViewModelTests: XCTestCase {

    func test_init_itemsConstructorInjected() {
        
        let items = [SampleItemViewModel(id: "1", name: "sample 1")]
        let sut = SampleSelectorViewModel(items: items)
        
        XCTAssertEqual(sut.items, items)
    }
}
