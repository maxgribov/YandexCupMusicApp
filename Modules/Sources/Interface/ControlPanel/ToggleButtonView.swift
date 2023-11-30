//
//  ToggleButtonView.swift
//
//
//  Created by Max Gribov on 03.11.2023.
//

import SwiftUI
import Presentation

struct ToggleButtonView: View {
    
    @ObservedObject var viewModel: ToggleButtonViewModel
    let action: () -> Void
    
    private var icon: Image {
        viewModel.isActive ? viewModel.type.iconActive : viewModel.type.icon
    }
    
    var body: some View {
        
        Button(action: action) {
            
            Color(.backPrimary)
                .frame(width: 34, height: 34)
                .clipShape(RoundedRectangle(cornerRadius: 4))
                .overlay {
                    icon.opacity(viewModel.isEnabled ? 1 : 0.5)
                }
            
        }.disabled(!viewModel.isEnabled)
    }
}

#Preview {
    
    ZStack {
        
        Color(.back)
        
        VStack {
            
            ToggleButtonView(viewModel: .init(type: .record, isActive: true, isEnabled: true)) {}
            ToggleButtonView(viewModel: .init(type: .record, isActive: false, isEnabled: false)) {}
        }
    }
}

extension ToggleButtonViewModel.Kind {
    
    var icon: Image {
        
        switch self {
        case .record: return Image(.iconMic)
        case .compose: return Image(.iconRecord)
        case .play: return Image(.iconPlay)
        }
    }
    
    var iconActive: Image {
        
        switch self {
        case .record: return Image(.iconMicActive)
        case .compose: return Image(.iconRecordActive)
        case .play: return Image(.iconPause)
        }
    }
}
