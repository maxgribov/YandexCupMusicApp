//
//  SampleSelectorViewModelTests.swift
//  
//
//  Created by Max Gribov on 31.10.2023.
//

import XCTest
import Samples

final class SampleSelectorViewModel {
    
    let buttons: [InstrumentButtonViewModel]
    
    init(buttons: [InstrumentButtonViewModel]) {
        
        self.buttons = buttons
    }
}

struct InstrumentButtonViewModel: Identifiable, Equatable {
    
    var id: String { instrument.rawValue }
    let instrument: Instrument
}

final class SampleSelectorViewModelTests: XCTestCase {

    func test_init_buttonsConstructorInjected() {
        
        let buttons: [InstrumentButtonViewModel] = [.init(instrument: .guitar)]
        let sut = SampleSelectorViewModel(buttons: buttons)
        
        XCTAssertEqual(sut.buttons, buttons)
    }

}
