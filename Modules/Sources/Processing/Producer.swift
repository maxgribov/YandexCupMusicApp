//
//  Producer.swift
//
//
//  Created by Max Gribov on 31.10.2023.
//

import Foundation
import Combine
import Domain

public final class Producer<P, R, C> where P: Player, R: Recorder, C: Composer {
    
    @Published public private(set) var layers: [Layer]
    @Published public private(set) var active: Layer.ID?
    private let delegateActionSubject = PassthroughSubject<DelegateAction, Never>()
    
    private var payloads = [Layer.ID: Payload]()
    
    private let player: P
    private let recorder: R
    private let composer: C
    private let playerEventsSubject = PassthroughSubject<TimeInterval?, Never>()
    
    private var cancellable: AnyCancellable?
    private var recording: AnyCancellable?
    private var playingTimer: AnyCancellable?
    private var compositing: AnyCancellable?
    
    public var delegateAction: AnyPublisher<DelegateAction, Never> {
        
        delegateActionSubject.eraseToAnyPublisher()
    }
    
    public var playingProgress: AnyPublisher<Double, Never> {

        playerEventsSubject.progressEvents()
    }
    
    public init(layers: [Layer] = [], active: Layer.ID? = nil, player: P, recorder: R, composer: C) {
        
        self.layers = layers
        self.active = active
        self.player = player
        self.recorder = recorder
        self.composer = composer
        
        cancellable = $layers
            .sink { [unowned self] layers in handleUpdate(layers: layers) }
        
        player.playing { [unowned self] duration in
            
            playerEventsSubject.send(duration)
        }
    }
}

//MARK: - Create Layers

public extension Producer {
    
    func addLayer(id: UUID = UUID(), for instrument: Instrument, with sample: Sample) {
        
        let layer = Layer(id: id, name: sampleLayerName(for: instrument), isPlaying: false, isMuted: false, control: .initial)
        payloads[layer.id] = .sample(instrument, sample)
        layers.append(layer)
        active = layer.id
    }
    
    func addLayer(id: UUID = UUID(), forRecording data: Data) {
        
        let layer = Layer(id: id, name: recordingLayerName(), isPlaying: false, isMuted: false, control: .initial)
        payloads[layer.id] = .recording(data)
        layers.append(layer)
        active = layer.id
    }
}

//MARK: - Update Layers

public extension Producer {
    
    func set(isPlaying: Bool, for layerID: Layer.ID) {
        
        var updated = [Layer]()
        
        for layer in layers {
            
            if layer.id == layerID {
                
                var updatedLayer = layer
                updatedLayer.isPlaying = isPlaying
                updated.append(updatedLayer)
             
            } else {
                
                updated.append(layer)
            }
        }
        
        layers = updated
    }
    
    func set(isMuted: Bool, for layerID: Layer.ID) {
        
        var updated = [Layer]()
        
        for layer in layers {
            
            if layer.id == layerID {
                
                var updatedLayer = layer
                updatedLayer.isMuted = isMuted
                updated.append(updatedLayer)
                
            } else {
                
                updated.append(layer)
            }
        }
        
        layers = updated
    }
    
    func delete(layerID: Layer.ID) {
        
        layers = layers.filter { $0.id != layerID }
        payloads.removeValue(forKey: layerID)
        
        if player.playing.contains(layerID) {
            
            player.stop(id: layerID)
        }
        
        if layers.count == 0 {
            
            active = nil
            
        } else if layerID == active {
            
            active = layers.last?.id
        }
    }
    
    func select(layerID: Layer.ID) {
        
        guard layers.map(\.id).contains(layerID) else {
            return
        }
        
        active = layerID
    }
    
    func setActiveLayer(control: Layer.Control) {
        
        guard let activeLayerID = active else {
            return
        }
        
        var updated = [Layer]()
        
        for layer in layers {
            
            if layer.id == activeLayerID {
                
                var updatedLayer = layer
                updatedLayer.control = control
                updated.append(updatedLayer)
                
            } else {
                
                updated.append(layer)
            }
        }
        
        layers = updated
        player.update(id: activeLayerID, with: control)
    }
}

//MARK: - Recordings

public extension Producer {
    
    func isRecording() -> AnyPublisher<Bool, Never> {
        
        recorder.isRecording()
    }
    
    func startRecording() {
        
        recording = recorder.startRecording()
            .sink(receiveCompletion: {[weak self] completion in
                
                switch completion {
                case .failure:
                    self?.delegateActionSubject.send(.recordingFailed)
                    
                case .finished:
                    break
                }
                
                self?.recording = nil
                
            }, receiveValue: {[weak self] data in
                
                self?.addLayer(forRecording: data)
            })
    }
    
    func stopRecording() {
        
        recorder.stopRecording()
    }
}

//MARK: - Compositing

public extension Producer {
    
    func isCompositing() -> AnyPublisher<Bool, Never> {
        
        composer.isCompositing()
    }
    
    func startCompositing() {
        
        let notMutedLayers = layers.filter({ $0.isMuted == false })
        let tracks = notMutedLayers.map { (layer) -> Track? in
            
            guard let data = payloads[layer.id]?.soundData else {
                return nil
            }
            
            return Track(with: layer, data: data)
        }
        .compactMap { $0 }
        
        guard tracks.isEmpty == false else {
            return
        }
        
        set(isPlayingAll: false)

        compositing = composer.compose(tracks: tracks)
            .map { DelegateAction.compositingReady($0) }
            .replaceError(with: DelegateAction.compositingFailed)
            .subscribe(delegateActionSubject)
    }
    
    func stopCompositing() {
        
        composer.stop()
    }
}

//MARK: - Playing All

public extension Producer {
    
    func set(isPlayingAll: Bool) {
        
        var updated = [Layer]()
        
        switch isPlayingAll {
        case true:
            
            for layer in layers {
                
                if layer.isMuted == false {
                    
                    var updatedLayer = layer
                    updatedLayer.isPlaying = true
                    updated.append(updatedLayer)
                    
                } else {
                    
                    updated.append(layer)
                }
            }

        case false:
            
            for layer in layers {
                
                if layer.isPlaying == true {
                    
                    var updatedLayer = layer
                    updatedLayer.isPlaying = false
                    updated.append(updatedLayer)
                    
                } else {
                    
                    updated.append(layer)
                }
            }
            break
        }
        
        layers = updated
    }
}

//MARK: - Types

public extension Producer {
    
    enum Payload {
        
        case sample(Instrument, Sample)
        case recording(Data)
        
        var instrument: Instrument? {
            
            guard case let .sample(instrument, _) = self else {
                return nil
            }
            
            return instrument
        }
        
        var isRecording: Bool {
            
            switch self {
            case .recording: return true
            default: return false
            }
        }
        
        var soundData: Data {
            
            switch self {
            case .sample(_, let sample):
                return sample.data
                
            case .recording(let data):
                return data
            }
        }
    }
    
    enum DelegateAction: Equatable {
        
        case recordingFailed
        case compositingReady(URL)
        case compositingFailed
    }
}

//MARK: - Private Helpers

private extension Producer {
    
    func handleUpdate(layers: [Layer]) {
        
        let layersPlaying = layers.filter { player.playing.contains($0.id) }
        let layersShouldPlay = layers.filter{ $0.isPlaying == true && $0.isMuted == false }
    
        for layer in layersPlaying {
            
            guard layersShouldPlay.map(\.id).contains(layer.id) == false else {
                continue
            }
            
            player.stop(id: layer.id)
        }
        
        for layer in layersShouldPlay {
            
            guard player.playing.contains(layer.id) == false,
                  let soundData = payloads[layer.id]?.soundData else {
                
                continue
            }
            
            player.play(id: layer.id, data: soundData, control: layer.control)
        }
    }
    
    func sampleLayerName(for instrument: Instrument) -> String {
        
        let currentLayersCount = payloads.values.compactMap(\.instrument).filter { $0 == instrument }.count
        
        return "\(instrument.name) \(currentLayersCount + 1)"
    }
    
    func recordingLayerName() -> String {
        
        let currentLayersCount = payloads.values.map(\.isRecording).filter { $0 }.count
        
        //TODO: localisation required
        return "Запись \(currentLayersCount + 1)"
    }
}
