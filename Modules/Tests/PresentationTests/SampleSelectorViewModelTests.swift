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
    
    func test_init_itemsConstructorInjected() {
        
        let items = [SampleItemViewModel(id: "1", name: "sample 1", isOdd: false)]
        let sut = makeSUT(items: items)
        
        XCTAssertEqual(sut.items, items)
    }
    
    func test_init_instrumentCorrectlyInjected() {
        
        let sut = makeSUT(instrument: .brass)
        
        XCTAssertEqual(sut.instrument, .brass)
    }
    
    func test_itemDidSelected_doesNotInformDelegateForWrongItemID() {
        
        let sut = makeSUT()
        
        expect(sut, delegateAction: nil, for: {
            
            sut.itemDidSelected(for: wrongItemID())
        })
    }
 
    func test_itemDidSelected_informDelegateSampleSelectedForIDOnCorrectItemID() {
        
        let sut = makeSUT(instrument: .brass, items: [.init(id: "1", name: "", isOdd: false)])
        
        let selectedSampleID = "1"
        expect(sut, delegateAction: .sampleDidSelected(selectedSampleID, .brass), for: {
            
            sut.itemDidSelected(for: selectedSampleID)
        })
    }
    
    //MARK: - Helpers
    
    private func makeSUT(
        instrument: Instrument = SampleSelectorViewModelTests.someInstrument(),
        items: [SampleItemViewModel] = SampleSelectorViewModelTests.sampleItems(),
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> SampleSelectorViewModel {
        
        let sut = SampleSelectorViewModel(instrument: instrument, items: items)
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
        
        let delegateSpy = ValueSpy(sut.delegateAction)
        
        action()
        
        XCTWaiter().wait(for: [], timeout: 0.01)
        
        if let expectedDelegateAction {
            
            XCTAssertEqual(delegateSpy.values, [expectedDelegateAction], "Expected action: \(expectedDelegateAction), got \(delegateSpy.values) instead", file: file, line: line)
            
        } else {
            
            XCTAssertTrue(delegateSpy.values.isEmpty, "Expected no actions, got \(delegateSpy.values) instead", file: file, line: line)
        }
    }
    
    private static func sampleItems() -> [SampleItemViewModel] {
        
        [.init(id: "1", name: "sample 1", isOdd: false),
         .init(id: "2", name: "sample 2", isOdd: true),
         .init(id: "3", name: "sample 3", isOdd: false)]
    }
    
    private func wrongItemID() -> SampleItemViewModel.ID {
        "wrong item id"
    }
    
    private static func loadSampleDummy(_ sampleID: Sample.ID) -> AnyPublisher<Sample, Error> {
        
        Empty().eraseToAnyPublisher()
    }
    
    private func anyNSError() -> NSError {
        
        NSError(domain: "", code: 0)
    }
    
    private static func someInstrument() -> Instrument {
        
        .guitar
    }
    
    private func anySample() -> Sample {
        
        Sample(id: "123", data: Data("sample-data".utf8))
    }
}
