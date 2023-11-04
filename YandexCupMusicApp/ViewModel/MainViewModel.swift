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
    private let layers: () -> AnyPublisher<LayersUpdate, Never>
    
    private var bindings = Set<AnyCancellable>()
    private var sampleSelectorTask: AnyCancellable?
    private var layersDelegateBinding: AnyCancellable?
    
    init(
        activeLayer: AnyPublisher<Layer?, Never>,
        samplesIDs: @escaping (Instrument) -> AnyPublisher<[Sample.ID], Error>,
        loadSample: @escaping (Sample.ID) -> AnyPublisher<Sample, Error>,
        layers: @escaping () -> AnyPublisher<LayersUpdate, Never>
    ) {
        
        self.instrumentSelector = .initial
        self.sampleControl = SampleControlViewModel(update: activeLayer.control())
        self.controlPanel = .initial
        self.samplesIDs = samplesIDs
        self.loadSample = loadSample
        self.layers = layers
        
        bind()
        bindings.insert(controlPanel.bind(activeLayer: activeLayer))
        
        layers().sink { [unowned self] update in
            
            if update.layers.isEmpty, layersControl != nil {
                dismissLayersControl()
            }
        }.store(in: &bindings)
    }
    
    var delegateAction: AnyPublisher<DelegateAction, Never> {
        
        delegateActionSubject.eraseToAnyPublisher()
    }
    
    func dismissSampleSelector() {
        
        sampleSelector = nil
    }
    
    func dismissLayersControl() {
        
        controlPanel.layersButtonDidTapped()
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
        case layersControl(LayersControlViewModel.DelegateAction)
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
            let layersControl = LayersControlViewModel(initial: [], updates: layers().makeLayerViewModels())
            self.layersControl = layersControl
            layersDelegateBinding = layersControl.delegateAction.sink(receiveValue: {[unowned self] action in
                delegateActionSubject.send(.layersControl(action))
            })
            
        case .hideLayers:
            layersControl = nil
            
        default:
            break
        }
    }
}

