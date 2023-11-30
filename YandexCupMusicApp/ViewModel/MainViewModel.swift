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
    @Published var playingProgress: Double
    @Published var sheet: Sheet?
    
    private let delegateActionSubject = PassthroughSubject<DelegateAction, Never>()
    private let layersUpdates: () -> AnyPublisher<LayersUpdate, Never>
    private let samplesIDs: (Instrument) -> AnyPublisher<[Sample.ID], Error>
    
    private var bindings = Set<AnyCancellable>()
    private var sampleSelectorBinding: AnyCancellable?
    private var sampleSelectorDelegate: AnyCancellable?
    private var layersDelegateBinding: AnyCancellable?
    
    init(
        instrumentSelector: InstrumentSelectorViewModel,
        sampleControl: SampleControlViewModel,
        controlPanel: ControlPanelViewModel,
        playingProgress: Double,
        activeLayerUpdates: AnyPublisher<Layer?, Never>,
        layersUpdated: @escaping () -> AnyPublisher<LayersUpdate, Never>,
        samplesIDs: @escaping (Instrument) -> AnyPublisher<[Sample.ID], Error>,
        playingProgressUpdate: AnyPublisher<Double, Never>,
        sheetUpdate: AnyPublisher<Sheet?, Never>
    ) {
        
        self.instrumentSelector = instrumentSelector
        self.sampleControl = sampleControl
        self.controlPanel = controlPanel
        self.playingProgress = playingProgress
        self.layersUpdates = layersUpdated
        self.samplesIDs = samplesIDs
        
        bind()
        bind(layersUpdated())
        bindings.insert(controlPanel.bind(activeLayer: activeLayerUpdates))
        playingProgressUpdate.assign(to: &$playingProgress)
        sheetUpdate.assign(to: &$sheet)
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
        
        case defaultSampleSelected(Instrument)
        case activeLayerUpdate(Layer.Control)
        case layersControl(LayersControlViewModel.DelegateAction)
        case sampleSelector(SampleSelectorViewModel.DelegateAction)
        case startRecording
        case stopRecording
        case startComposing
        case stopComposing
        case startPlaying
        case stopPlaying
    }
    
    enum Sheet: Identifiable, Hashable {
        
        var id: Self { self }
        
        case activity(URL)
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
    
    func bind(_ layers:  AnyPublisher<LayersUpdate, Never>) {
        
        layers.sink { [unowned self] update in
            
            if update.layers.isEmpty, layersControl != nil {
                
                dismissLayersControl()
            }
            
        }.store(in: &bindings)
    }
    
    func handleInstrumentSelector(delegateAction: InstrumentSelectorViewModel.DelegateAction) {
        
        switch delegateAction {
        case let .selectDefaultSample(instrument):
            delegateActionSubject.send(.defaultSampleSelected(instrument))
            
        case let .showSampleSelector(instrument):
            sampleSelectorBinding = samplesIDs(instrument)
                .makeSampleItemViewModels()
                .sink(receiveCompletion: { _ in }) { [unowned self] items in
                    
                    let sampleSelector = SampleSelectorViewModel(instrument: instrument, items: items)
                    self.sampleSelector = sampleSelector
                    
                    sampleSelectorDelegate = sampleSelector.delegateAction
                        .handleEvents(receiveOutput: {[unowned self] action in
                            switch action {
                            case .sampleDidSelected:
                                dismissSampleSelector()
                            }
                        })
                        .map { MainViewModel.DelegateAction.sampleSelector($0) }
                        .subscribe(delegateActionSubject)
                }
        }
    }
    
    func handleSampleControl(delegateAction: SampleControlViewModel.DelegateAction) {
        
        switch delegateAction {
        case let .controlDidUpdated(control):
            delegateActionSubject.send(.activeLayerUpdate(control))
        }
    }
    
    func handleControlPanel(delegateAction: ControlPanelViewModel.DelegateAction) {
        
        switch delegateAction {
        case .showLayers:
            let layersControl = LayersControlViewModel(initial: [], updates: layersUpdates().makeLayerViewModels())
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
