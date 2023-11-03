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
    
    private let delegateActionSubject = PassthroughSubject<DelegateAction, Never>()
    private var cancellables = Set<AnyCancellable>()

    init(activeLayer: AnyPublisher<Layer?, Never>) {
        
        self.instrumentSelector = .initial
        self.sampleControl = SampleControlViewModel(update: activeLayer.compactMap{ $0?.control }.eraseToAnyPublisher())
        self.controlPanel = .initial
        
        instrumentSelector.delegateAction
            .sink { [unowned self] action in
                
                switch action {
                case let .selectDefaultSample(instrument):
                    delegateActionSubject.send(.addLayerWithDefaultSampleFor(instrument))
                    
                default:
                    break
                }
                
            }.store(in: &cancellables)
    }
    
    var delegateAction: AnyPublisher<DelegateAction, Never> {
        
        delegateActionSubject.eraseToAnyPublisher()
    }
}

extension MainViewModel {
    
    enum DelegateAction: Equatable {
        
        case addLayerWithDefaultSampleFor(Instrument)
    }
}

extension InstrumentSelectorViewModel {
    
    static let initial = InstrumentSelectorViewModel(buttons: [.init(instrument: .guitar),
                                                               .init(instrument: .drums),
                                                               .init(instrument: .brass)])
}


final class MainViewModelTests: XCTestCase {

    func test_init_instrumentsContainsCorrectButtons() {
        
        let sut = makeSUT()
        
        XCTAssertEqual(sut.instrumentSelector.buttons.map(\.instrument), [.guitar, .drums, .brass])
    }
    
    func test_init_sampleControlWithControlNil() {
        
        let sut = makeSUT()

        XCTAssertNil(sut.sampleControl.control)
    }
    
    func test_init_controlPanelContainsCorrectButtons() {
        
        let sut = makeSUT()
        
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
    
    func test_instrumentSelectorButtonDidTapped_informDlegateCreateNewLayerWithDefaultSampleForInstrument() {
        
        let sut = makeSUT()
        let delegateActionSpy = ValueSpy(sut.delegateAction)
        
        sut.instrumentSelector.buttonDidTapped(for: Instrument.brass.rawValue)
        
        XCTAssertEqual(delegateActionSpy.values, [.addLayerWithDefaultSampleFor(.brass)])
    }
    
    //MARK: - Helpers
    
    private func makeSUT(
        activeLayer: AnyPublisher<Layer?, Never> = Empty().eraseToAnyPublisher(),
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> MainViewModel {
        
        let sut = MainViewModel(activeLayer: activeLayer)
        trackForMemoryLeaks(sut, file: file, line: line)
        
        return sut
        
    }
}
