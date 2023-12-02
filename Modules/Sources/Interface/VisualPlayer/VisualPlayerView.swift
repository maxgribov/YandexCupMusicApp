//
//  VisualPlayerView.swift
//  
//
//  Created by Yandex KZ on 02.12.2023.
//

import SwiftUI
import Combine
import Presentation

public struct VisualPlayerView: View {
    
    @ObservedObject var viewModel: VisualPlayerViewModel
    
    public init(viewModel: VisualPlayerViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        
        VStack {
        
            // top pannel
            
            HStack {
                
                Button(action: viewModel.backButtonDidTapped) {
                    
                    Image(.buttonBack)
                }
                
                Text(viewModel.title)
                    .foregroundStyle(Color(.textSecondary))
                
                Spacer()
                
                Image(.buttonExport)
                
            }.padding()
            
            VisualPlayerCanvasView(shapes: viewModel.shapes) { area in
                viewModel.canvasAreaDidUpdated(area: area)
            }
            
            //TODO: progress control
            EmptyView()
                .frame(height: 40)
            
            // bottom controls
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
    let areaUpdate: (CGRect) -> Void
    
    var body: some View {
        
        GeometryReader{ geometry in
            
            ForEach(shapes) { shape in
                
                VisualPlayerShapeView(viewModel: shape)
            }
            .onAppear {
                
                areaUpdate(geometry.frame(in: .local))
            }
        }
    }
}

struct VisualPlayerShapeView: View {
    
    @ObservedObject var viewModel: VisualPlayerShapeViewModel
    
    var body: some View {
        
        viewModel.image
            .resizable()
            .frame(width: 256, height: 256)
            .scaleEffect(viewModel.scale)
            .position(viewModel.position)
    }
}

extension VisualPlayerShapeViewModel {
    
    var image: Image {
        
        switch name {
        case "fig_1": Image(.fig1)
        case "fig_2": Image(.fig2)
        case "fig_3": Image(.fig3)
        case "fig_4": Image(.fig4)
        case "fig_5": Image(.fig5)
        case "fig_6": Image(.fig6)
        case "fig_7": Image(.fig7)
        case "fig_8": Image(.fig8)
        case "fig_9": Image(.fig9)
        case "fig_10": Image(.fig10)
        case "fig_11": Image(.fig11)
        case "fig_12": Image(.fig12)
        case "fig_13": Image(.fig13)
        case "fig_14": Image(.fig14)
        case "fig_15": Image(.fig15)
        default: Image("")
        }
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
                    makeShapes: { _ in VisualPlayerViewModel.generateRandomShapes(area: .init(x: 0, y: 0, width: 500, height: 700)) },
                    canvasArea: .zero,
                    audioControl: .init(
                        playButton: .init(isPlaying: false)),
                    trackUpdates: Empty().eraseToAnyPublisher(),
                    playerStateUpdates: Empty().eraseToAnyPublisher()))
    }
}
