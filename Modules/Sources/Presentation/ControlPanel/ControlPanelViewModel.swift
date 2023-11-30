//
//  ControlPanelViewModel.swift
//
//
//  Created by Max Gribov on 03.11.2023.
//

import Foundation
import Combine

public final class ControlPanelViewModel {
    
    public let layersButton: LayersButtonViewModel
    public let recordButton: ToggleButtonViewModel
    public let composeButton: ToggleButtonViewModel
    public let playButton: ToggleButtonViewModel
    
    private let delegateActionSubject = PassthroughSubject<DelegateAction, Never>()
    
    public init(
        layersButton: LayersButtonViewModel,
        recordButton: ToggleButtonViewModel,
        composeButton: ToggleButtonViewModel,
        playButton: ToggleButtonViewModel,
        layersButtonNameUpdates: AnyPublisher<String?, Never>,
        composeButtonStatusUpdates: AnyPublisher<Bool, Never>,
        playButtonStatusUpdates: AnyPublisher<Bool, Never>
    ) {
        self.layersButton = layersButton
        self.recordButton = recordButton
        self.composeButton = composeButton
        self.playButton = playButton
        
        layersButtonNameUpdates
            .map { $0 ?? Self.layersButtonDefaultName }
            .assign(to: &self.layersButton.$name)
        
        layersButtonNameUpdates
            .map { name in

                switch name {
                case .some:
                    return self.isLayersButtonEnabled()
                    
                case .none:
                    return false
                }
                
            }.assign(to: &self.layersButton.$isEnabled)
        
        composeButtonStatusUpdates.assign(to: &self.composeButton.$isActive)
        playButtonStatusUpdates.assign(to: &self.playButton.$isActive)
    }
    
    public var delegateAction: AnyPublisher<DelegateAction, Never> {
        
        delegateActionSubject.eraseToAnyPublisher()
    }
    
    public func layersButtonDidTapped() {
        
        layersButton.isActive.toggle()
        delegateActionSubject.send(layersButton.isActive ? .showLayers : .hideLayers)
        set(all: [recordButton, composeButton, playButton], to: !layersButton.isActive)
    }
    
    public func recordButtonDidTapped() {
        
        recordButton.isActive.toggle()
        delegateActionSubject.send(recordButton.isActive ? .startRecording : .stopRecording)
        if layersButton.name == Self.layersButtonDefaultName {
            
            set(all: [composeButton, playButton], to: !recordButton.isActive)
            
        } else {
            
            set(all: [layersButton, composeButton, playButton], to: !recordButton.isActive)
        }
    }
    
    public func composeButtonDidTapped() {
        
        composeButton.isActive.toggle()
        delegateActionSubject.send(composeButton.isActive ? .startComposing : .stopComposing)
        if layersButton.name == Self.layersButtonDefaultName {
            
            set(all: [recordButton, playButton], to: !composeButton.isActive)
            
        } else {
            
            set(all: [layersButton, recordButton, playButton], to: !composeButton.isActive)
        }
    }
    
    public func playButtonDidTapped() {
        
        playButton.isActive.toggle()
        delegateActionSubject.send(playButton.isActive ? .startPlaying : .stopPlaying)
        set(all: [recordButton, composeButton], to: !playButton.isActive)
    }
    
    private func set(all items: [Enablable], to isEnabled: Bool) {
        
        for var item in items {
            
            item.isEnabled = isEnabled
        }
    }
    
    private func isLayersButtonEnabled() -> Bool {
        
        [recordButton, composeButton, playButton]
            .map(\.isActive)
            .reduce(false, { partialResult, value in partialResult || value }) == false
    }
    
    public static let layersButtonDefaultName = "Слои"
}

public extension ControlPanelViewModel {
    
    enum DelegateAction: Equatable {
        
        case showLayers
        case hideLayers
        case startRecording
        case stopRecording
        case startComposing
        case stopComposing
        case startPlaying
        case stopPlaying
    }
}
