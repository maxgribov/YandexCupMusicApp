//
//  MainViewModelTests.swift
//  YandexCupMusicAppTests
//
//  Created by Max Gribov on 03.11.2023.
//

import XCTest
import Combine
import Domain
import Presentation

final class MainViewModel {
    
    let instrumentSelector: InstrumentSelectorViewModel
    let sampleControl: SampleControlViewModel

    init(activeLayer: AnyPublisher<Layer?, Never>) {
        
        self.instrumentSelector = .initial
        self.sampleControl = SampleControlViewModel(update: activeLayer.compactMap{ $0?.control }.eraseToAnyPublisher())
    }
}

extension InstrumentSelectorViewModel {
    
    static let initial = InstrumentSelectorViewModel(buttons: [.init(instrument: .guitar),
                                                               .init(instrument: .drums),
                                                               .init(instrument: .brass)])
}


final class MainViewModelTests: XCTestCase {

    func test_init_instrumentsContainsCorrectButtons() {
        
        let sut = MainViewModel(activeLayer: Empty().eraseToAnyPublisher())
        
        XCTAssertEqual(sut.instrumentSelector.buttons.map(\.instrument), [.guitar, .drums, .brass])
    }
    
    func test_init_sampleControlWithControlNil() {
        
        let sut = MainViewModel(activeLayer: Empty().eraseToAnyPublisher())

        XCTAssertNil(sut.sampleControl.control)
    }

}
