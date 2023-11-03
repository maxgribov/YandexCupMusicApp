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

final class MainViewModel: ObservableObject {
    
    let instrumentSelector: InstrumentSelectorViewModel
    let sampleControl: SampleControlViewModel
    let controlPanel: ControlPanelViewModel
    
    @Published var sampleSelector: SampleSelectorViewModel?
    
    private let delegateActionSubject = PassthroughSubject<DelegateAction, Never>()
    private let samplesIDs: (Instrument) -> AnyPublisher<[Sample.ID], Error>
    private let loadSample: (Sample.ID) -> AnyPublisher<Sample, Error>
    
    private var cancellables = Set<AnyCancellable>()
    private var sampleSelectorTask: AnyCancellable?
    
    init(
        activeLayer: AnyPublisher<Layer?, Never>,
        samplesIDs: @escaping (Instrument) -> AnyPublisher<[Sample.ID], Error>,
        loadSample: @escaping (Sample.ID) -> AnyPublisher<Sample, Error>
    ) {
        
        self.instrumentSelector = .initial
        self.sampleControl = SampleControlViewModel(update: activeLayer.compactMap{ $0?.control }.eraseToAnyPublisher())
        self.controlPanel = .initial
        self.samplesIDs = samplesIDs
        self.loadSample = loadSample
        
        instrumentSelector.delegateAction
            .sink { [unowned self] action in
                
                switch action {
                case let .selectDefaultSample(instrument):
                    delegateActionSubject.send(.addLayerWithDefaultSampleFor(instrument))
                    
                case let .showSampleSelector(instrument):
                    sampleSelectorTask = samplesIDs(instrument)
                        .makeSampleItemViewModels()
                        .sink(receiveCompletion: {[unowned self] _ in
                            
                            sampleSelectorTask = nil
                            
                        }) {[unowned self] items in
                            
                            sampleSelector = .init(instrument: instrument, items: items, loadSample: loadSample)
                            sampleSelectorTask = nil
                        }
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

extension Publisher where Output == [Sample.ID], Failure == Error {
    
    func makeSampleItemViewModels() -> AnyPublisher<[SampleItemViewModel], Error> {
        
        map { result in
            
            var items = [SampleItemViewModel]()
            for (index, sampleID) in result.enumerated() {
                
                let item = SampleItemViewModel(id: sampleID, name: "сэмпл \(index)", isOdd: index % 2 > 0)
                items.append(item)
            }
            
            return items
            
        }.eraseToAnyPublisher()
    }
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
    
    func test_init_sampleSelectorNil() {
        
        let sut = makeSUT()
        
        XCTAssertNil(sut.sampleSelector)
    }
    
    func test_instrumentSelectorButtonDidTapped_informDlegateCreateNewLayerWithDefaultSampleForInstrument() {
        
        let sut = makeSUT()
        let delegateActionSpy = ValueSpy(sut.delegateAction)
        
        sut.instrumentSelector.buttonDidTapped(for: Instrument.brass.rawValue)
        
        XCTAssertEqual(delegateActionSpy.values, [.addLayerWithDefaultSampleFor(.brass)])
    }
    
    func test_instrumentSelectorButtonDidLongTapped_createsSampleSelectorViewModel() {
        
        let sut = makeSUT(samplesIDs: { _ in Just([Sample.ID(), Sample.ID(), Sample.ID()]).setFailureType(to: Error.self).eraseToAnyPublisher() })
        
        sut.instrumentSelector.buttonDidLongTapped(for: Instrument.guitar.rawValue)
        
        XCTAssertEqual(sut.sampleSelector?.instrument, .guitar)
    }
    
    //MARK: - Helpers
    
    private func makeSUT(
        activeLayer: AnyPublisher<Layer?, Never> = Empty().eraseToAnyPublisher(),
        samplesIDs: @escaping (Instrument) -> AnyPublisher<[Sample.ID], Error> = { _ in Empty().eraseToAnyPublisher()},
        loadSample: @escaping (Sample.ID) -> AnyPublisher<Sample, Error> = { _ in Empty().eraseToAnyPublisher()},
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> MainViewModel {
        
        let sut = MainViewModel(activeLayer: activeLayer, samplesIDs: samplesIDs, loadSample: loadSample)
        trackForMemoryLeaks(sut, file: file, line: line)
        
        return sut
        
    }
}
