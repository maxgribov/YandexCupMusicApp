//
//  InstrumentSelectorViewModelTests.swift
//  
//
//  Created by Max Gribov on 31.10.2023.
//

import XCTest
import Domain
import Presentation
import Combine

final class InstrumentSelectorViewModelTests: XCTestCase {
    
    func test_init_buttonsConstructorInjected() {
        
        let buttons: [InstrumentButtonViewModel] = [.init(instrument: .guitar)]
        let sut = makeSUT(buttons: buttons)
        
        XCTAssertEqual(sut.buttons, buttons)
    }
    
    func test_buttonDidTapped_doesNotInformDelegateForWrongID() {
        
        let sut = makeSUT()
        
        expect(sut, delegateAction: nil, for: {
            
            sut.buttonDidTapped(for: wrongInstrumentButtonViewModelID())
        })
    }
    
    func test_buttonDidTapped_informDelegateInstrumentTappedForInstrumentButtonID() {
        
        let sut = makeSUT()
        let selectedButton = sut.buttons[0]
        
        expect(sut, delegateAction: .selectDefaultSample(selectedButton.instrument), for: {
            
            sut.buttonDidTapped(for: selectedButton.id)
        })
    }
    
    func test_buttonDidLongTapped_doesNotInformDelegateForWrongID() {
        
        let sut = makeSUT()
        
        expect(sut, delegateAction: nil, for: {
            
            sut.buttonDidLongTapped(for: wrongInstrumentButtonViewModelID())
        })
    }
    
    func test_buttonDidLongTapped_informDelegateInstrumentLongTappedForInstrumentButtonID() {
        
        let sut = makeSUT()
        let selectedButton = sut.buttons[1]
        
        expect(sut, delegateAction: .showSampleSelector(selectedButton.instrument), for: {
            
            sut.buttonDidLongTapped(for: selectedButton.id)
        })
    }

    //MARK: - Helpers
    
    private func makeSUT(
        buttons: [InstrumentButtonViewModel] = InstrumentSelectorViewModelTests.sampleButtons(),
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> InstrumentSelectorViewModel {
        
        let sut = InstrumentSelectorViewModel(buttons: buttons)
        trackForMemoryLeaks(sut, file: file, line: line)
        
        return sut
    }
    
    private func expect(
        _ sut: InstrumentSelectorViewModel,
        delegateAction expectedDelegateAction: InstrumentSelectorViewModel.DelegateAction?,
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
    
    private static func sampleButtons() -> [InstrumentButtonViewModel] {
        
        Instrument.allCases.map(InstrumentButtonViewModel.init)
    }
    
    private func wrongInstrumentButtonViewModelID() -> InstrumentButtonViewModel.ID {
        "wrong id"
    }
}
