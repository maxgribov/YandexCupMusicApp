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
    
    let playButtonDidTapped: () -> Void
    let muteButtonDidTapped: () -> Void
    let selectDidTapped: () -> Void
    let deleteButtonDidTapped: () -> Void
    
    var body: some View {
        
        HStack(spacing: 0) {
            
            Text(viewModel.name)
                .foregroundStyle(Color(.textPrimary))
                .padding(.leading, 10)
            
            Spacer()
            
            Button(action: playButtonDidTapped) {
                
                Image(viewModel.isPlaying ? .iconPause : .iconPlay)
                
            }.frame(width: 44, height: 44)
            
            Button(action: muteButtonDidTapped) {
                
                Image(viewModel.isMuted ? .iconMuted : .iconNotMuted)
                
            }.frame(width: 44, height: 44)
            
            Button(action: deleteButtonDidTapped) {
                
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
                playButtonDidTapped: {},
                muteButtonDidTapped: {},
                selectDidTapped: {},
                deleteButtonDidTapped: {}
            )
            
            LayerView(
                viewModel: .init(id: UUID(), name: "Guitar 1", isPlaying: false, isMuted: true, isActive: false),
                playButtonDidTapped: {},
                muteButtonDidTapped: {},
                selectDidTapped: {},
                deleteButtonDidTapped: {}
            )
            
            LayerView(
                viewModel: .init(id: UUID(), name: "Drums 2", isPlaying: true, isMuted: false, isActive: true),
                playButtonDidTapped: {},
                muteButtonDidTapped: {},
                selectDidTapped: {},
                deleteButtonDidTapped: {}
            )
            
        }.padding()
    }
}
