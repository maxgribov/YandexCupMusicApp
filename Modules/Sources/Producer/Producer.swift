//
//  Producer.swift
//
//
//  Created by Max Gribov on 31.10.2023.
//

import Foundation
import Combine
import Samples

public final class Producer {
    
    @Published public private(set) var layers: [Layer]
    @Published public private(set) var active: Layer.ID?
    @Published public private(set) var isPlayingAll: Bool
    public let delegateActionSubject = PassthroughSubject<DelegateAction, Never>()
    
    private var payloads: [Layer.ID: Payload]
    
    private let player: any Player
    private let recorder: any Recorder
    
    private var cancellable: AnyCancellable?
    private var recording: AnyCancellable?
    
    public init(player: any Player, recorder: any Recorder) {
        
        self.layers = []
        self.active = nil
        self.isPlayingAll = false
        self.payloads = [:]
        self.player = player
        self.recorder = recorder
        
        cancellable = $layers
            .sink { [unowned self] layers in handleUpdate(layers: layers) }
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
                
            } else if isPlaying == true, layer.isPlaying == true {
                
                var updatedLayer = layer
                updatedLayer.isPlaying = false
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
    }
    
    func select(layerID: Layer.ID) {
        
        guard layers.map(\.id).contains(layerID) else {
            return
        }
        
        active = layerID
    }
}

//MARK: - Recordings

public extension Producer {
    
    func isRecording() -> AnyPublisher<Bool, Never> {
        
        recorder.isRecording()
    }
    
    func startRecording() {
        
        do {
            
            recording = try recorder.startRecording()
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
            
        } catch {
            
            delegateActionSubject.send(.startRecordingFailed)
        }
    }
    
    func stopRecording() {
        
        recorder.stopRecording()
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
        self.isPlayingAll = isPlayingAll
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
        
        case startRecordingFailed
        case recordingFailed
    }
}

//MARK: - Private Helpers

private extension Producer {
    
    func handleUpdate(layers: [Layer]) {
        
        let layersShouldPlay = layers.filter{ $0.isPlaying == true && $0.isMuted == false }
        
        for layerID in player.playing {
            
            guard layersShouldPlay.map(\.id).contains(layerID) == false else {
                continue
            }
            
            player.stop(id: layerID)
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
