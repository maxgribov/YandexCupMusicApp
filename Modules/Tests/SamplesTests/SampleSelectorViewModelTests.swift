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
    
    let buttons: [InstrumentButtonViewModel]
    let delegateActionSubject = PassthroughSubject<DelegateAction, Never>()
    
    init(buttons: [InstrumentButtonViewModel]) {
        
        self.buttons = buttons
    }
    
    func buttonDidTapped(for buttonID: InstrumentButtonViewModel.ID) {
        
        guard let buttonViewModel = buttons.first(where: { $0.id == buttonID }) else {
            return
        }
        
        delegateActionSubject.send(.instrumentDidSelected(buttonViewModel.instrument))
    }
}

extension SampleSelectorViewModel {
    
    enum DelegateAction: Equatable {
        
        case instrumentDidSelected(Instrument)
    }
}

struct InstrumentButtonViewModel: Identifiable, Equatable {
    
    var id: String { instrument.rawValue }
    let instrument: Instrument
}

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

        var receivedDelegateAction: SampleSelectorViewModel.DelegateAction? = nil
        sut.delegateActionSubject
            .sink { receivedDelegateAction = $0 }
            .store(in: &cancellables)
        
        sut.buttonDidTapped(for: wrongInstrumentButtonViewModelID())
        
        XCTWaiter().wait(for: [], timeout: 0.01)
        
        XCTAssertNil(receivedDelegateAction)
    }
    
    func test_buttonDidTapped_informDelegateInstrumentSelectedForInstrumentButtonID() {
        
        let sut = makeSUT()
        let selectedButton = sut.buttons[0]
        
        var receivedDelegateAction: SampleSelectorViewModel.DelegateAction? = nil
        sut.delegateActionSubject
            .sink { receivedDelegateAction = $0 }
            .store(in: &cancellables)
        
        sut.buttonDidTapped(for: selectedButton.id)
        
        XCTWaiter().wait(for: [], timeout: 0.01)
        
        XCTAssertEqual(receivedDelegateAction, .instrumentDidSelected(selectedButton.instrument))
    }

    //MARK: - Helpers
    
    private func makeSUT(
        buttons: [InstrumentButtonViewModel] = SampleSelectorViewModelTests.sampleButtons()
    ) -> SampleSelectorViewModel {
        
        let sut = SampleSelectorViewModel(buttons: buttons)
        
        return sut
    }
    
    private static func sampleButtons() -> [InstrumentButtonViewModel] {
        
        Instrument.allCases.map(InstrumentButtonViewModel.init)
    }
    
    private func wrongInstrumentButtonViewModelID() -> InstrumentButtonViewModel.ID {
        "wrong id"
    }
}
