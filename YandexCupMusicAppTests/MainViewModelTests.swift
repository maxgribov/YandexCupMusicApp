//
//  MainViewModelTests.swift
//  YandexCupMusicAppTests
//
//  Created by Max Gribov on 03.11.2023.
//

import XCTest
import Combine
import Presentation

final class MainViewModel {
    
    let instrumentSelector: InstrumentSelectorViewModel = .initial

    init() {}
}

extension InstrumentSelectorViewModel {
    
    static let initial = InstrumentSelectorViewModel(buttons: [.init(instrument: .guitar),
                                                               .init(instrument: .drums),
                                                               .init(instrument: .brass)])
}


final class MainViewModelTests: XCTestCase {

    func test_init_instrumentsContainsCorrectButtons() {
        
        let sut = MainViewModel()
        
        XCTAssertEqual(sut.instrumentSelector.buttons.map(\.instrument), [.guitar, .drums, .brass])
    }

}
