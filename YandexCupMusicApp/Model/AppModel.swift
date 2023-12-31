//
//  AppModel.swift
//  YandexCupMusicApp
//
//  Created by Max Gribov on 04.11.2023.
//

import Foundation
import AVFoundation
import Combine
import Domain
import Processing
import Persistence
import Presentation

final class AppModel<S, A, P, R, C> where S: SamplesLocalStore, A: AVAudioSessionProtocol, P: Player, R: Recorder, C: Composer {
    
    let producer: Producer<P, R, C>
    let localStore: S
    private let sessionConfigurator: FoundationRecordingSessionConfigurator<A>
    
    private var bindings = Set<AnyCancellable>()
    private var defaultSampleRequest: AnyCancellable?
    private var loadSampleBinding: AnyCancellable?
    
    init(producer: Producer<P, R, C>, localStore: S, sessionConfigurator: FoundationRecordingSessionConfigurator<A>) {
        
        self.producer = producer
        self.localStore = localStore
        self.sessionConfigurator = sessionConfigurator
    }
    
    func mainViewModel() -> MainViewModel {
        
        let viewModel = MainViewModel(
            instrumentSelector: .initial,
            sampleControl: .init(update: producer.activeLayerControlUpdates()),
            controlPanel: .init(
                layersButton: .init(name: .layersButtonDefaultName, isActive: false, isEnabled: true),
                recordButton: .init(type: .record, isActive: false, isEnabled: true),
                composeButton: .init(type: .compose, isActive: false, isEnabled: true),
                playButton: .init(type: .play, isActive: false, isEnabled: true),
                layersButtonNameUpdates: producer.layersButtonNameUpdates(),
                composeButtonStatusUpdates: producer.composeButtonStatusUpdates(),
                playButtonStatusUpdates: producer.playButtonStatusUpdates()
            ),
            playingProgress: 0,
            makeSampleSelector: localStore.makeSampleSelector(instrument:),
            makeLayersControl: producer.makeLayersControl,
            playingProgressUpdates: producer.playingProgress,
            sheetUpdates: producer.sheetUpdates()
        )
        bindMainViewModel(delegate: viewModel.delegateAction)
        
        return viewModel
    }
    
    func bindMainViewModel(delegate: AnyPublisher<MainViewModel.DelegateAction, Never>) {
        
        delegate.sink {[unowned self] action in
            
            switch action {
            case let .defaultSampleSelected(instrument):
                defaultSampleRequest = localStore.defaultSample(for: instrument)
                    .sink(receiveCompletion: {[unowned self] _ in
                        
                        self.defaultSampleRequest = nil
                        
                    }, receiveValue: {[unowned self] sample in
                        
                        producer.addLayer(for: instrument, with: sample)
                        self.defaultSampleRequest = nil
                    })
                
            case let .layersControl(layerAction):
                switch layerAction {
                case let .isPlayingDidChanged(layerID, isPlaying):
                    producer.set(isPlaying: isPlaying, for: layerID)
                    
                case let .isMutedDidChanged(layerID, isMuted):
                    producer.set(isMuted: isMuted, for: layerID)
                    
                case let .selectLayer(layerID):
                    producer.select(layerID: layerID)
                    
                case let .deleteLayer(layerID):
                    producer.delete(layerID: layerID)
                    
                case .dismiss:
                    break
                }
            
            case let .activeLayerUpdate(control):
                producer.setActiveLayer(control: control)
                
            case .startPlaying:
                producer.set(isPlayingAll: true)
                
            case .stopPlaying:
                producer.set(isPlayingAll: false)
                
            case let .sampleSelector(sampleSelectorAction):
                switch sampleSelectorAction {
                case let .sampleDidSelected(sampleID, instrument):
                    loadSampleBinding = localStore.loadSample(sampleID: sampleID)
                        .sink(receiveCompletion: { _ in }, receiveValue: { [unowned self] sample in
                            
                            producer.addLayer(for: instrument, with: sample)
                        })
                }
                
            case .startRecording:
                sessionConfigurator
                    .isRecordingEnabled()
                    .sink(receiveCompletion: { _ in }, receiveValue: { [unowned self] isEnabled in
                        
                        if isEnabled {
                            
                            producer.startRecording()
                        }
                        
                    }).store(in: &bindings)
                
            case .stopRecording:
                producer.stopRecording()
                
            case .startComposing:
                producer.startCompositing()
                
            case .stopComposing:
                producer.stopCompositing()
            }
            
        }.store(in: &bindings)
    }
}
