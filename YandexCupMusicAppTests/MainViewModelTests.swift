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
    @Published var layersControl: LayersControlViewModel?
    
    private let delegateActionSubject = PassthroughSubject<DelegateAction, Never>()
    private let samplesIDs: (Instrument) -> AnyPublisher<[Sample.ID], Error>
    private let loadSample: (Sample.ID) -> AnyPublisher<Sample, Error>
    private let layers: () -> AnyPublisher<([Layer], Layer.ID?), Never>
    
    private var bindings = Set<AnyCancellable>()
    private var sampleSelectorTask: AnyCancellable?
    
    init(
        activeLayer: AnyPublisher<Layer?, Never>,
        samplesIDs: @escaping (Instrument) -> AnyPublisher<[Sample.ID], Error>,
        loadSample: @escaping (Sample.ID) -> AnyPublisher<Sample, Error>,
        layers: @escaping () -> AnyPublisher<([Layer], Layer.ID?), Never>
    ) {
        
        self.instrumentSelector = .initial
        self.sampleControl = SampleControlViewModel(update: activeLayer.control())
        self.controlPanel = .initial
        self.samplesIDs = samplesIDs
        self.loadSample = loadSample
        self.layers = layers
        
        instrumentSelector.delegateAction
            .sink { [unowned self] action in
                
                handleInstrumentSelector(delegateAction: action)
                
            }.store(in: &bindings)
        
        sampleControl.delegateAction
            .sink { [unowned self] action in
                
                switch action {
                case let .controlDidUpdated(control):
                    delegateActionSubject.send(.activeLayerControlUpdate(control))
                }
                
            }.store(in: &bindings)
        
        controlPanel.delegateAction
            .sink { [unowned self] action in
                
                switch action {
                case .showLayers:
                    layersControl = LayersControlViewModel(initial: [], updates: layers().makeLayerViewModels())
                    
                case .hideLayers:
                    layersControl = nil
                    
                default:
                    break
                }
                
            }.store(in: &bindings)
    }
    
    var delegateAction: AnyPublisher<DelegateAction, Never> {
        
        delegateActionSubject.eraseToAnyPublisher()
    }
    
    private func handleInstrumentSelector(delegateAction: InstrumentSelectorViewModel.DelegateAction) {
        
        switch delegateAction {
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
    }
}

extension MainViewModel {
    
    enum DelegateAction: Equatable {
        
        case addLayerWithDefaultSampleFor(Instrument)
        case activeLayerControlUpdate(Layer.Control)
    }
}

extension InstrumentSelectorViewModel {
    
    static let initial = InstrumentSelectorViewModel(buttons: [.init(instrument: .guitar),
                                                               .init(instrument: .drums),
                                                               .init(instrument: .brass)])
}

extension Publisher where Output == Layer?, Failure == Never {
    
    func control() -> AnyPublisher<Layer.Control?, Never> {
        
        map(\.?.control).eraseToAnyPublisher()
    }
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

extension Publisher where Output == ([Layer], Layer.ID?), Failure == Never {
    
    func makeLayerViewModels() -> AnyPublisher<[LayerViewModel], Never> {
        
        map { (layers, activeID) in
            
            var viewModels = [LayerViewModel]()
            for layer in layers {
                
                let viewModel = LayerViewModel(id: layer.id, name: layer.name, isPlaying: layer.isPlaying, isMuted: layer.isMuted, isActive: layer.id == activeID)
                viewModels.append(viewModel)
            }
            
            return viewModels
            
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
    
    func test_activeLevel_setsAndRemovesControlValueForSampleControl() {
        
        let activeLayerStub = PassthroughSubject<Layer?, Never>()
        let sut = makeSUT(activeLayer: activeLayerStub.eraseToAnyPublisher())
        
        XCTAssertNil(sut.sampleControl.control)
        
        let layer = someLayer()
        activeLayerStub.send(someLayer())
        XCTAssertEqual(sut.sampleControl.control, layer.control)
        
        activeLayerStub.send(nil)
        XCTAssertNil(sut.sampleControl.control)
    }
    
    func test_sampleControlKnobOffsetDidChanged_informsDelegateCurrentLayerControlUpdate() {
        
        let sut = makeSUT(activeLayer: Just(someLayer()).eraseToAnyPublisher())
        let delegateActionSpy = ValueSpy(sut.delegateAction)

        sut.sampleControl.knobOffsetDidChanged(offset: .zero, area: .init(width: 100, height: 100))
        
        XCTAssertEqual(delegateActionSpy.values, [.activeLayerControlUpdate(.init(volume: 0.5, speed: 0.5))])
    }
    
    func test_controlPanelLayersButtonDidTapped_createsAndRemovesLayersControl() {
        
        let sut = makeSUT()
        
        sut.controlPanel.layersButtonDidTapped()
        XCTAssertNotNil(sut.layersControl)
        
        sut.controlPanel.layersButtonDidTapped()
        XCTAssertNil(sut.layersControl)
    }
    
    //MARK: - Helpers
    
    private func makeSUT(
        activeLayer: AnyPublisher<Layer?, Never> = Empty().eraseToAnyPublisher(),
        samplesIDs: @escaping (Instrument) -> AnyPublisher<[Sample.ID], Error> = { _ in Empty().eraseToAnyPublisher()},
        loadSample: @escaping (Sample.ID) -> AnyPublisher<Sample, Error> = { _ in Empty().eraseToAnyPublisher()},
        layers: @escaping () -> AnyPublisher<([Layer], Layer.ID?), Never> = { Empty().eraseToAnyPublisher() },
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> MainViewModel {
        
        let sut = MainViewModel(activeLayer: activeLayer, samplesIDs: samplesIDs, loadSample: loadSample, layers: layers)
        trackForMemoryLeaks(sut, file: file, line: line)
        
        return sut
        
    }
    
    private func someLayer() -> Layer {
        
        Layer(id: UUID(), name: "layer 1", isPlaying: true, isMuted: false, control: .init(volume: 0.7, speed: 1.0))
    }
}
