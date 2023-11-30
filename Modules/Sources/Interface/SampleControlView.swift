//
//  SampleControlView.swift
//
//
//  Created by Max Gribov on 02.11.2023.
//

import SwiftUI
import Combine
import Presentation

public struct SampleControlView: View {

    @ObservedObject var viewModel: SampleControlViewModel
    
    @State var knobOffset: CGSize = .zero
    @State var lastEnded: CGSize = .zero
    
    public init(viewModel: SampleControlViewModel) {
        
        self.viewModel = viewModel
    }
    
    public var body: some View {
        
        GeometryReader { proxy in
            
            ZStack {
                
                GradientBackgroundView()
                VolumeRulerView(height: proxy.size.height)
                SpeedRulerView(width: proxy.size.width)
                
                if viewModel.isKnobPresented {
                    
                    ControlKnobView(knobOffset: $knobOffset, lastEnded: $lastEnded, area: proxy.size)
                        .onReceive(viewModel.$control) { value in
                            
                            knobOffset = viewModel.knobOffset(with: value, in: proxy.size.offset(translation: .init(width: -60, height: -60)))
                            lastEnded = viewModel.knobOffset(with: value, in: proxy.size.offset(translation: .init(width: -60, height: -60)))
                        }
                        .onChange(of: knobOffset) { newValue in
                            
                            viewModel.knobOffsetDidChanged(offset: newValue, area: proxy.size.offset(translation: .init(width: -60, height: -60)))
                        }
                }
            }
        }
    }
}

#Preview {
    ZStack {
        
        Color(.back)
        
        SampleControlView(viewModel: .init(initial: nil, update: Just(.init(volume: 0.7, speed: 0.3)).eraseToAnyPublisher()))
            .padding()
    }
}


extension SampleControlView {
    
    struct GradientBackgroundView: View {
        
        var body: some View {
            
            LinearGradient(gradient: Gradient(colors: [Color(.backControl).opacity(0.1), Color(.backControl)]), startPoint: .top, endPoint: .bottom)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }
    
    struct SpeedRulerView: View {
        
        let width: CGFloat
        var segments: Int { Int(width / 19) }
        
        var body: some View {
            
            VStack {
                
                Spacer()
                
                HStack {
                    
                    Spacer()
                    
                    ForEach((0..<segments).reversed(), id: \.self) { value in
                        
                        HStack(spacing: 0) {
                            
                            Color.clear
                                .frame(width: CGFloat(value), height: 14)
                            
                            Capsule()
                                .frame(width: 1, height: 14)
                                .foregroundStyle(Color(.backPrimary))
                        }
                    }
                }
                
            }.padding(5)
        }
    }
    
    struct VolumeRulerView: View {
        
        let height: CGFloat
        var segments: Int { Int(height / 70) }
        
        var body: some View {
            HStack {
                VStack(spacing: 11) {
                    
                    ForEach( 0..<segments, id: \.self) { _ in
                        volumeSegment()
                    }
                }
                Spacer()
                
            }.padding(.leading, 5)
        }
        
        func volumeSegment() -> some View {
            
            VStack(alignment: .leading, spacing: 11) {
                
                Capsule()
                    .frame(width: 14, height: 1)
                    .foregroundStyle(Color(.backPrimary))
                
                ForEach(0..<5) { _ in
                    
                    Capsule()
                        .frame(width: 7, height: 1)
                        .foregroundStyle(Color(.backPrimary))
                    
                }
            }
        }
    }
    
    struct ControlKnobView: View {
        
        @Binding var knobOffset: CGSize
        @Binding var lastEnded: CGSize
        let area: CGSize
        @State private var isDragging: Bool = false
        
        var body: some View {
            
            Circle()
                .frame(width: 60, height: 60)
                .foregroundStyle(Color(.backAccent))
                .scaleEffect(isDragging ? 2.0 : 1.0)
                .offset(knobOffset)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            
                            knobOffset = lastEnded.offset(translation: value.translation)
                                .limit(area: area.offset(translation: .init(width: -60, height: -60)))
                            isDragging = true
                        }
                        .onEnded { value in
                            
                            lastEnded = knobOffset
                            isDragging = false
                        }
                )
        }
        
        func knobOffset(lastEnded: CGSize, translation: CGSize) -> CGSize {
            
            CGSize(width: lastEnded.width + translation.width ,
                                   height: lastEnded.height + translation.height)
        }
    }
}
