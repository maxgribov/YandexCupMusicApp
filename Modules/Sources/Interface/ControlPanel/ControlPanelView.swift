//
//  ControlPanelView.swift
//
//
//  Created by Max Gribov on 03.11.2023.
//

import SwiftUI
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
        
        ControlPanelView(viewModel: .initial)
            .padding()
    }
}





