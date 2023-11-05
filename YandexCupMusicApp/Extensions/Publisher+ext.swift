//
//  Publisher+ext.swift
//  YandexCupMusicApp
//
//  Created by Max Gribov on 03.11.2023.
//

import Foundation
import Combine
import Domain
import Presentation

extension Publisher where Output == Layer?, Failure == Never {
    
    func control() -> AnyPublisher<Layer.Control?, Never> {
        
        map(\.?.control).eraseToAnyPublisher()
    }
}

extension Publisher where Output == [Sample.ID], Failure == Error {
    
    func makeSampleItemViewModels() -> AnyPublisher<[SampleItemViewModel], Error> {
        
        map { result in
            
            var items = [SampleItemViewModel]()
            for (index, sampleID) in result.enumerated() {
                
                let item = SampleItemViewModel(id: sampleID, name: "сэмпл \(index)", isOdd: index % 2 > 0)
                items.append(item)
            }
            
            return items
            
        }.eraseToAnyPublisher()
    }
}

extension Publisher where Output == LayersUpdate, Failure == Never {
    
    func makeLayerViewModels() -> AnyPublisher<[LayerViewModel], Never> {
        
        map { update in
            
            var viewModels = [LayerViewModel]()
            for layer in update.layers {
                
                let viewModel = LayerViewModel(id: layer.id, name: layer.name, isPlaying: layer.isPlaying, isMuted: layer.isMuted, isActive: layer.id == update.active)
                viewModels.append(viewModel)
            }
            
            return viewModels
            
        }.eraseToAnyPublisher()
    }
}

extension Publisher where Output == ControlPanelViewModel.DelegateAction, Failure == Never {
    
    func forwardActions() -> AnyPublisher<MainViewModel.DelegateAction, Never> {
        
        compactMap { out in
            
            switch out {
            case .startRecording:
                return MainViewModel.DelegateAction.startRecording
                
            case .stopRecording:
                return MainViewModel.DelegateAction.stopRecording
                
            case .startComposing:
                return MainViewModel.DelegateAction.startComposing
                
            case .stopComposing:
                return MainViewModel.DelegateAction.stopComposing
                
            case .startPlaying:
                return MainViewModel.DelegateAction.startPlaying
                
            case .stopPlaying:
                return MainViewModel.DelegateAction.stopPlaying
                
            default:
                return nil
            }
            
        }.eraseToAnyPublisher()
    }
}

extension Publisher where Output == LayersUpdate, Failure == Never {
    
    func isPlayingAll() -> AnyPublisher<Bool, Never> {
        
        compactMap{ $0.layers.isEmpty == true ? nil : $0.layers }
        .map{ $0.map(\.isPlaying).reduce(true, { result, current in result && current }) }
        .removeDuplicates()
        .eraseToAnyPublisher()
    }
}

