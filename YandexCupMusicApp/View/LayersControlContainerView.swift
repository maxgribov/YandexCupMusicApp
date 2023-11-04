//
//  LayersControlContainerView.swift
//  YandexCupMusicApp
//
//  Created by Max Gribov on 04.11.2023.
//

import SwiftUI
import Combine
import Presentation
import Interface

struct LayersControlContainerView: View {
    
    let viewModel: LayersControlViewModel
    let dismissAction: () -> Void
    
    var body: some View {
        
        ZStack(alignment: .bottom) {
            
            Color.black
                .opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture(perform: dismissAction)
            
            LayersControlView(viewModel: viewModel)
                .padding(.bottom, 120)
        }
    }
}

#Preview {
    LayersControlContainerView(
        viewModel: LayersControlViewModel(
            initial: [.init(id: UUID(), name: "Drums 1", isPlaying: false, isMuted: false, isActive: false),
                      .init(id: UUID(), name: "Guitar 1", isPlaying: true, isMuted: false, isActive: false),
                      .init(id: UUID(), name: "Brass 1", isPlaying: false, isMuted: false, isActive: true)],
            updates: Empty().eraseToAnyPublisher()),
        dismissAction: {})
}
