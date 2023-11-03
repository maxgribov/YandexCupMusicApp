//
//  LayersButtonView.swift
//
//
//  Created by Max Gribov on 03.11.2023.
//

import SwiftUI
import Presentation

struct LayersButtonView: View {
    
    @ObservedObject var viewModel: LayersButtonViewModel
    let action: () -> Void
    
    var body: some View {
        
        Button(action: action) {
            
            HStack {
                
                Text(viewModel.name)
                    .foregroundStyle(Color(.textPrimary))
                
                Image(.iconChevronDown)
                    .rotationEffect(viewModel.isActive ? .degrees(180) : .zero)
            }
            .opacity(viewModel.isEnabled ? 1 : 0.5)
            .frame(height: 34)
            .padding(.horizontal, 8)
            .background(
                Color(viewModel.isActive ? .backAccent : .backPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            )
            
        }.disabled(!viewModel.isEnabled)
    }
}

#Preview {
    
    ZStack {
        
        Color(.back)
        
        VStack {
            LayersButtonView(viewModel: .initial, action: {})
            LayersButtonView(viewModel: .init(name: "Active", isActive: true, isEnabled: true), action: {})
            LayersButtonView(viewModel: .init(name: "Disabled", isActive: false, isEnabled: false), action: {})
        }
    }
}
