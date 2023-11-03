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
    let controlPanel: ControlPanelViewModel

    init(activeLayer: AnyPublisher<Layer?, Never>) {
        
        self.instrumentSelector = .initial
        self.sampleControl = SampleControlViewModel(update: activeLayer.compactMap{ $0?.control }.eraseToAnyPublisher())
        self.controlPanel = .initial
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
    
    func test_init_controlPanelContainsCorrectButtons() {
        
        let sut = MainViewModel(activeLayer: Empty().eraseToAnyPublisher())
        
        XCTAssertEqual(sut.controlPanel.layersButton.name, "Слои")
        XCTAssertEqual(sut.controlPanel.layersButton.isActive, false)
        XCTAssertEqual(sut.controlPanel.layersButton.isEnabled, true)
        
        XCTAssertEqual(sut.controlPanel.recordButton.type, .record)
        XCTAssertEqual(sut.controlPanel.layersButton.isActive, false)
        XCTAssertEqual(sut.controlPanel.layersButton.isEnabled, true)
        
        XCTAssertEqual(sut.controlPanel.composeButton.type, .compose)
        XCTAssertEqual(sut.controlPanel.layersButton.isActive, false)
        XCTAssertEqual(sut.controlPanel.layersButton.isEnabled, true)
        
        XCTAssertEqual(sut.controlPanel.playButton.type, .play)
        XCTAssertEqual(sut.controlPanel.layersButton.isActive, false)
        XCTAssertEqual(sut.controlPanel.layersButton.isEnabled, true)

    }

}
