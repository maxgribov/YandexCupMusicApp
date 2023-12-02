//
//  VisualPlayerView.swift
//  
//
//  Created by Yandex KZ on 02.12.2023.
//

import SwiftUI
import Combine
import Presentation

struct VisualPlayerView: View {
    
    @ObservedObject var viewModel: VisualPlayerViewModel
    
    var body: some View {
        
        VStack {
            
            HStack {
                
                Button(action: viewModel.backButtonDidTapped) {
                    
                    Image(.buttonBack)
                }
                
                Text(viewModel.title)
                    .foregroundStyle(Color(.textSecondary))
                
                Spacer()
                
                Image(.buttonExport)
                
            }.padding()
            
            GeometryReader { geometry in
                
                Text("Canvas")
            }
            
            //TODO: progress control
            EmptyView()
                .frame(height: 40)
            
            HStack {
                
                Button(action: viewModel.rewindButtonDidTapped) {
                    
                    Image(systemName: "backward.fill")
                        .foregroundStyle(Color(.backAccent))
                }
                .frame(width: 44, height: 44)
                
                Button(action: viewModel.playButtonDidTapped) {
                    
                    Image(systemName: "play.fill")
                        .foregroundStyle(Color(.backAccent))
                }
                .frame(width: 44, height: 44)
                
                Button(action: viewModel.fastForwardButtonDidTapped) {
                    
                    Image(systemName: "forward.fill")
                        .foregroundStyle(Color(.backAccent))
                }
                .frame(width: 44, height: 44)
            }
        }
    }
}

struct VisualPlayerCanvasView: View {
    
    let shapes: [VisualPlayerShapeViewModel]
    
    var body: some View {
        
        GeometryReader{ geometry in
            
            ForEach(shapes) { shape in
                
                shape.image
            }
        }
    }
}

extension VisualPlayerShapeViewModel {
    
    var image: Image {
        
        Image(name)
    }
}

#Preview {
    ZStack {
        
        Color(.back)
            .ignoresSafeArea()
        
        VisualPlayerView(viewModel:
                .init(
                    layerID: UUID(),
                    title: "Track name",
                    makeShapes: { _ in [] },
                    audioControl: .init(
                        playButton: .init(isPlaying: false)),
                    trackUpdates: Empty().eraseToAnyPublisher(),
                    playerStateUpdates: Empty().eraseToAnyPublisher()))
    }
}
