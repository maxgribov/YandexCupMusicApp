//
//  ControlPanelViewModel+ext.swift
//  YandexCupMusicApp
//
//  Created by Max Gribov on 04.11.2023.
//

import Foundation
import Combine
import Domain
import Presentation

extension ControlPanelViewModel {
    
    func bind(activeLayer: AnyPublisher<Layer?, Never>) -> AnyCancellable {
        
        activeLayer
            .sink {[unowned self] layer in
                
                if let layer {
                    
                    layersButton.name = layer.name
                    
                    if [recordButton, composeButton, playButton]
                        .map(\.isActive)
                        .reduce(false, { partialResult, value in partialResult || value }) == false {
                        
                        layersButton.isEnabled = true
                    }
                    
                } else {
                    
                    layersButton.name = ControlPanelViewModel.layersButtonDefaultName
                    layersButton.isEnabled = false
                }
            }
    }
}
