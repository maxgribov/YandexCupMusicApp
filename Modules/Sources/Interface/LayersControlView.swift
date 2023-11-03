//
//  LayersControlView.swift
//
//
//  Created by Max Gribov on 02.11.2023.
//

import SwiftUI
import Combine
import Presentation

struct LayersControlView: View {
    
    @ObservedObject var viewModel: LayersControlViewModel
    
    var body: some View {
        
        VStack {
            
            ForEach(viewModel.layers) { layerViewModel in
            
                LayerView(viewModel: layerViewModel)
            }
            
        }.padding(.horizontal)
    }
}

#Preview {
    
    ZStack {
        
        Color(.back)
        
        LayersControlView(viewModel: .init(
            initial: [
                .init(id: UUID(), name: "Drums 1", isPlaying: false, isMuted: false, isActive: false),
                .init(id: UUID(), name: "Guitar 1", isPlaying: true, isMuted: false, isActive: true),
                .init(id: UUID(), name: "Brass 1", isPlaying: false, isMuted: true, isActive: false),
            ],
            updates: Empty().eraseToAnyPublisher()))
    }
}