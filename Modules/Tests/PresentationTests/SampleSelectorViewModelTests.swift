//
//  SampleSelectorViewModelTests.swift
//  
//
//  Created by Max Gribov on 31.10.2023.
//

import XCTest
import Samples
import Presentation
import Combine

final class SampleSelectorViewModelTests: XCTestCase {
    
    var cancellables = Set<AnyCancellable>()
    
    override func setUp() async throws {
        try await super.setUp()
        
        cancellables = []
    }

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
    
    func test_buttonDidTapped_informDelegateInstrumentSelectedForInstrumentButtonID() {
        
        let sut = makeSUT()
        let selectedButton = sut.buttons[0]
        
        expect(sut, delegateAction: .instrumentDidSelected(selectedButton.instrument), for: {
            
            sut.buttonDidTapped(for: selectedButton.id)
        })
    }

    //MARK: - Helpers
    
    private func makeSUT(
        buttons: [InstrumentButtonViewModel] = SampleSelectorViewModelTests.sampleButtons()
    ) -> SampleSelectorViewModel {
        
        let sut = SampleSelectorViewModel(buttons: buttons)
        trackForMemoryLeaks(sut)
        
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
    
    private static func sampleButtons() -> [InstrumentButtonViewModel] {
        
        Instrument.allCases.map(InstrumentButtonViewModel.init)
    }
    
    private func wrongInstrumentButtonViewModelID() -> InstrumentButtonViewModel.ID {
        "wrong id"
    }
}
