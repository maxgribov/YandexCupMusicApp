//
//  MainView.swift
//  YandexCupMusicApp
//
//  Created by Max Gribov on 04.11.2023.
//

import SwiftUI
import Combine
import Interface

struct MainView: View {
    
    @ObservedObject var viewModel: MainViewModel
    
    var body: some View {
        
        VStack(spacing: 13) {
            
            InstrumentSelectorView(viewModel: viewModel.instrumentSelector)
            SampleControlView(viewModel: viewModel.sampleControl)
            SoundWaveProgressView(progress: .constant(0))
                .frame(height: 30)
            ControlPanelView(viewModel: viewModel.controlPanel)
            
        }.padding()
    }
}

#Preview {
    
    ZStack {
        
        Color.black
            .ignoresSafeArea()
        
        MainView(viewModel: MainViewModel(
            activeLayer: Empty().eraseToAnyPublisher(),
            samplesIDs: { _ in Empty().eraseToAnyPublisher() },
            loadSample: { _ in Empty().eraseToAnyPublisher()},
            layers: { Empty().eraseToAnyPublisher() }))
    }
}
