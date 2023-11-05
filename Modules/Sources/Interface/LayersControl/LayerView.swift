//
//  LayerView.swift
//
//
//  Created by Max Gribov on 02.11.2023.
//

import SwiftUI
import Presentation

struct LayerView: View {
    
    let viewModel: LayerViewModel
    
    var body: some View {
        
        HStack(spacing: 0) {
            
            Text(viewModel.name)
                .foregroundStyle(Color(.textPrimary))
                .padding(.leading, 10)
            
            Spacer()
            
            Button(action: viewModel.playButtonDidTaped) {
                
                Image(viewModel.isPlaying ? .iconPause : .iconPlay)
                
            }.frame(width: 44, height: 44)
            
            Button(action: viewModel.muteButtonDidTapped) {
                
                Image(viewModel.isMuted ? .iconMuted : .iconNotMuted)
                
            }.frame(width: 44, height: 44)
            
            Button(action: viewModel.deleteButtonDidTapped) {
                
                RoundedRectangle(cornerRadius: 4)
                    .foregroundColor(Color(.backMiddle))
                    .overlay { Image(.iconCross) }
                    .frame(width: 44, height: 44)
            }
            
        }.background {
            RoundedRectangle(cornerRadius: 4)
                .foregroundColor(Color(viewModel.isActive ? .backAccent : .backPrimary))
        }.onTapGesture {
            viewModel.selectDidTapped()
        }
    }
}

#Preview {
    
    ZStack {
        
        Color(.back)
        
        VStack {
            
            LayerView(viewModel: .init(id: UUID(), name: "Drums 1", isPlaying: false, isMuted: false, isActive: false))
            
            LayerView(viewModel: .init(id: UUID(), name: "Guitar 1", isPlaying: false, isMuted: true, isActive: false))
            
            LayerView(viewModel: .init(id: UUID(), name: "Drums 2", isPlaying: true, isMuted: false, isActive: true))
            
        }.padding()
    }
}
