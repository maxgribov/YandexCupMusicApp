//
//  ControlPanelView.swift
//
//
//  Created by Max Gribov on 03.11.2023.
//

import SwiftUI
import Combine
import Presentation

public struct ControlPanelView: View {

    let viewModel: ControlPanelViewModel
    
    public init(viewModel: ControlPanelViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        
        HStack {
            
            LayersButtonView(viewModel: viewModel.layersButton, action: viewModel.layersButtonDidTapped)
            
            Spacer()
            
            ToggleButtonView(viewModel: viewModel.recordButton, action: viewModel.recordButtonDidTapped)
            ToggleButtonView(viewModel: viewModel.composeButton, action: viewModel.composeButtonDidTapped)
            ToggleButtonView(viewModel: viewModel.playButton, action: viewModel.playButtonDidTapped)
        }
    }
}

#Preview {
    
    ZStack {
        
        Color(.back)
        
        ControlPanelView(
            viewModel: .init(
                layersButton: .init(name: ControlPanelViewModel.layersButtonDefaultName, isActive: false, isEnabled: true),
                recordButton: .init(type: .record, isActive: false, isEnabled: true),
                composeButton: .init(type: .compose, isActive: false, isEnabled: true),
                playButton: .init(type: .play, isActive: false, isEnabled: true),
                composeButtonStatusUpdates: Empty().eraseToAnyPublisher(),
                playButtonStatusUpdates: Empty().eraseToAnyPublisher()))
            .padding()
    }
}





