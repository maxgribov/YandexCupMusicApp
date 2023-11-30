//
//  MainView.swift
//  YandexCupMusicApp
//
//  Created by Max Gribov on 04.11.2023.
//

import SwiftUI
import Combine
import Interface
import Presentation

struct MainView: View {
    
    @ObservedObject var viewModel: MainViewModel
    
    var body: some View {
        
        ZStack {
            
            VStack(spacing: 13) {
                
                InstrumentSelectorView(viewModel: viewModel.instrumentSelector)
                SampleControlView(viewModel: viewModel.sampleControl)
                SoundWaveProgressView(progress: $viewModel.playingProgress)
                    .frame(height: 30)
                ControlPanelView(viewModel: viewModel.controlPanel)
                
            }.padding()
            
            if let sampleSelector = viewModel.sampleSelector {
                
                SampleSelectorContainerView(viewModel: sampleSelector, dismissAction: viewModel.dismissSampleSelector)
                    .padding()
            }
            
            if let layersControl = viewModel.layersControl {
                
                LayersControlContainerView(viewModel: layersControl, dismissAction: viewModel.dismissLayersControl)
            }
        }
        .sheet(item: $viewModel.sheet) { sheet in
            
            switch sheet {
            case let .activity(url):
                ActivityView(activityItems: [url], applicationActivities: nil)
            }
        }
    }
}

#Preview {
    
    ZStack {
        
        Color.black
            .ignoresSafeArea()
        
        MainView(viewModel: MainViewModel(
            instrumentSelector: .initial,
            sampleControl: .init(initial: nil, update: Empty().eraseToAnyPublisher()),
            controlPanel: .init(
                layersButton: .init(
                    name: "Layers", isActive: false, isEnabled: true),
                recordButton: .init(type: .record, isActive: false, isEnabled: true),
                composeButton: .init(type: .compose, isActive: false, isEnabled: true),
                playButton: .init(type: .play, isActive: false, isEnabled: true),
                layersButtonNameUpdates: Empty().eraseToAnyPublisher(),
                composeButtonStatusUpdates: Empty().eraseToAnyPublisher(),
                playButtonStatusUpdates: Empty().eraseToAnyPublisher()
            ),
            playingProgress: 0,
            makeLayersControl: { LayersControlViewModel(initial: [], updates: Empty().makeLayerViewModels()) },
            samplesIDs: { _ in Empty().eraseToAnyPublisher() },
            playingProgressUpdate: Empty().eraseToAnyPublisher(),
            sheetUpdate: Empty().eraseToAnyPublisher()
        ))
    }
}
