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
    
    let playButtonDidTapped: (LayerViewModel.ID) -> Void
    let muteButtonDidTapped: (LayerViewModel.ID) -> Void
    let selectDidTapped: () -> Void
    
    var body: some View {
        
        HStack(spacing: 0) {
            
            Text(viewModel.name)
                .foregroundStyle(Color(.textPrimary))
                .padding(.leading, 10)
            
            Spacer()
            
            Button(action: { playButtonDidTapped(viewModel.id) }) {
                
                Image(viewModel.isPlaying ? .iconPause : .iconPlay)
                
            }.frame(width: 44, height: 44)
            
            Button(action: { muteButtonDidTapped(viewModel.id) }) {
                
                Image(viewModel.isMuted ? .iconMuted : .iconNotMuted)
                
            }.frame(width: 44, height: 44)
            
            Button(action: viewModel.deleteButtonDidTapped) {
                
                RoundedRectangle(cornerRadius: 4)
                    .foregroundStyle(Color(.backMiddle))
                    .overlay { Image(.iconCross) }
                    .frame(width: 44, height: 44)
            }
            
        }.background {
            
            RoundedRectangle(cornerRadius: 4)
                .foregroundStyle(Color(viewModel.isActive ? .backAccent : .backPrimary))
            
        }.onTapGesture {
            
            selectDidTapped()
        }
    }
}

#Preview {
    
    ZStack {
        
        Color(.back)
        
        VStack {
            
            LayerView(
                viewModel: .init(id: UUID(), name: "Drums 1", isPlaying: false, isMuted: false, isActive: false), 
                playButtonDidTapped: { _ in },
                muteButtonDidTapped: { _ in },
                selectDidTapped: {}
            )
            
            LayerView(
                viewModel: .init(id: UUID(), name: "Guitar 1", isPlaying: false, isMuted: true, isActive: false),
                playButtonDidTapped: { _ in },
                muteButtonDidTapped: { _ in },
                selectDidTapped: {}
            )
            
            LayerView(
                viewModel: .init(id: UUID(), name: "Drums 2", isPlaying: true, isMuted: false, isActive: true),
                playButtonDidTapped: { _ in },
                muteButtonDidTapped: { _ in },
                selectDidTapped: {}
            )
            
        }.padding()
    }
}
