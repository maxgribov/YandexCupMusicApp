//
//  ControlPanelView.swift
//
//
//  Created by Max Gribov on 03.11.2023.
//

import SwiftUI
import Presentation

struct ControlPanelView: View {
    
    let viewModel: ControlPanelViewModel
    
    var body: some View {
        
        LayersButtonView(viewModel: viewModel.layersButton, action: viewModel.layersButtonDidTapped)
    }
}

#Preview {
    ZStack {
        
        Color(.back)
        
        ControlPanelView(viewModel: .initial)
    }
}





