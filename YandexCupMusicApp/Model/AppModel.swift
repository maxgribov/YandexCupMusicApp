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

final class AppModel<S, C> where S: SamplesLocalStore, C: AVAudioSessionProtocol {
    
    let producer: Producer
    let localStore: S
    let sessionConfigurator: FoundationRecordingSessionConfigurator<C>
    
    private var bindings = Set<AnyCancellable>()
    private var defaultSampleRequest: AnyCancellable?
    private var loadSampleBinding: AnyCancellable?
    
    init(producer: Producer, localStore: S, sessionConfigurator: FoundationRecordingSessionConfigurator<C>) {
        
        self.producer = producer
        self.localStore = localStore
        self.sessionConfigurator = sessionConfigurator
    }
    
    func mainViewModel() -> MainViewModel {
        
        let viewModel = MainViewModel(
            activeLayer: producer.activeLayerMain(),
            layers: producer.layersMain,
            samplesIDs: localStore.sampleIDsMain(for:),
            playingProgressUpdates: producer.playingProgress)
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
                
            default:
                break
            }
            
        }.store(in: &bindings)
    }
}

extension AppModel where S == BundleSamplesLocalStore, C == AVAudioSession {
    
    static let prod = AppModel(
        producer: Producer(
            player: FoundationPlayer(makePlayer: { data in try AVAudioPlayer(data: data) }),
            recorder: FoundationRecorder(makeRecorder: { url, settings in try AVAudioRecorder(url: url, settings: settings) })),
        localStore: BundleSamplesLocalStore(),
        sessionConfigurator: .init(session: AVAudioSession.sharedInstance()))
}

extension AVAudioSession: AVAudioSessionProtocol {}
