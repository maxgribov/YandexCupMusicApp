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
        playButton: ToggleButtonViewModel
    ) {
        self.layersButton = layersButton
        self.recordButton = recordButton
        self.composeButton = composeButton
        self.playButton = playButton
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
        set(all: [layersButton, composeButton, playButton], to: !recordButton.isActive)
    }
    
    public func composeButtonDidTapped() {
        
        composeButton.isActive.toggle()
        delegateActionSubject.send(composeButton.isActive ? .startComposing : .stopComposing)
        set(all: [layersButton, recordButton, playButton], to: !composeButton.isActive)
    }
    
    public func playButtonDidTapped() {
        
        playButton.isActive.toggle()
        delegateActionSubject.send(playButton.isActive ? .startPlaying : .stopPlaying)
        set(all: [layersButton, recordButton, composeButton], to: !playButton.isActive)
    }
    
    private func set(all items: [Enablable], to isEnabled: Bool) {
        
        for var item in items {
            
            item.isEnabled = isEnabled
        }
    }
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
    
    static let initial = ControlPanelViewModel(layersButton: .initial, recordButton: .initialRecord, composeButton: .initialCompose, playButton: .initialPlay)
}