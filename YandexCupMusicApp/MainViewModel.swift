//
//  MainViewModel.swift
//  YandexCupMusicApp
//
//  Created by Max Gribov on 03.11.2023.
//

import Foundation
import Combine
import Domain
import Presentation

final class MainViewModel: ObservableObject {
    
    let instrumentSelector: InstrumentSelectorViewModel
    let sampleControl: SampleControlViewModel
    let controlPanel: ControlPanelViewModel
    
    @Published private(set) var sampleSelector: SampleSelectorViewModel?
    @Published private(set) var layersControl: LayersControlViewModel?
    
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
        
        bind()
    }
    
    var delegateAction: AnyPublisher<DelegateAction, Never> {
        
        delegateActionSubject.eraseToAnyPublisher()
    }
}

//MARK: - Types

extension MainViewModel {
    
    enum DelegateAction: Equatable {
        
        case addLayerWithDefaultSampleFor(Instrument)
        case activeLayerControlUpdate(Layer.Control)
        case startRecording
        case stopRecording
        case startComposing
        case stopComposing
        case startPlaying
        case stopPlaying
    }
}

//MARK: - Private Helpers

private extension MainViewModel {
    
    func bind() {
        
        instrumentSelector.delegateAction
            .sink { [unowned self] action in handleInstrumentSelector(delegateAction: action) }
            .store(in: &bindings)
        
        sampleControl.delegateAction
            .sink { [unowned self] action in handleSampleControl(delegateAction: action) }
            .store(in: &bindings)
        
        controlPanel.delegateAction
            .sink { [unowned self] action in handleControlPanel(delegateAction: action) }
            .store(in: &bindings)
        
        controlPanel.delegateAction
            .forwardActions()
            .subscribe(delegateActionSubject)
            .store(in: &bindings)
    }
    
    func handleInstrumentSelector(delegateAction: InstrumentSelectorViewModel.DelegateAction) {
        
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
    
    func handleSampleControl(delegateAction: SampleControlViewModel.DelegateAction) {
        
        switch delegateAction {
        case let .controlDidUpdated(control):
            delegateActionSubject.send(.activeLayerControlUpdate(control))
        }
    }
    
    func handleControlPanel(delegateAction: ControlPanelViewModel.DelegateAction) {
        
        switch delegateAction {
        case .showLayers:
            layersControl = LayersControlViewModel(initial: [], updates: layers().makeLayerViewModels())
            
        case .hideLayers:
            layersControl = nil
            
        default:
            break
        }
    }
}
