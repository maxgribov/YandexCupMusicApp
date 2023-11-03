//
//  SampleControlView.swift
//
//
//  Created by Max Gribov on 02.11.2023.
//

import SwiftUI
import Combine
import Presentation

struct SampleControlView: View {
    
    @ObservedObject var viewModel: SampleControlViewModel
    
    @State var knobOffset: CGSize = .zero
    @State var lastEnded: CGSize = .zero
    @State var isDragging: Bool = false
    
    var body: some View {
        
        GeometryReader { proxy in
            
            ZStack {
                
                LinearGradient(gradient: Gradient(colors: [Color(.backControl).opacity(0.1), Color(.backControl)]), startPoint: .top, endPoint: .bottom)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                
                volumeRulerView(for: proxy.size.height)
                speedRulerView(for: proxy.size.width)
                
                Circle()
                    .frame(width: 60, height: 60)
                    .foregroundColor(Color(.backAccent))
                    .scaleEffect(isDragging ? 2.0 : 1.0)
                    .offset(knobOffset)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                
                                knobOffset = knobOffset(lastEnded: lastEnded,
                                                        translation: value.translation)
                                isDragging = true
                            }
                            .onEnded { value in
                                
                                lastEnded = knobOffset
                                isDragging = false
                            }
                    )
            }
        }
    }
    
    func knobOffset(lastEnded: CGSize, translation: CGSize) -> CGSize {
        
        let newOffset = CGSize(width: lastEnded.width + translation.width ,
               height: lastEnded.height + translation.height)
        
        return newOffset
    }

    func volumeSegmentsCount(for height: CGFloat) -> Int {
        
       Int(height / 70)
    }
    
    func volumeRulerView(for height: CGFloat) -> some View {
        
        HStack {
            VStack(spacing: 11) {
                
                ForEach( 0..<volumeSegmentsCount(for: height), id: \.self) { _ in
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
                .foregroundColor(Color(.backPrimary))
            
            ForEach(0..<5) { _ in
                
                Capsule()
                    .frame(width: 7, height: 1)
                    .foregroundColor(Color(.backPrimary))
                
            }
        }
    }
    
    func speedSegmentsCount(for width: CGFloat) -> Int {
        
        Int(width / 19)
    }
    
    func speedRulerView(for width: CGFloat) -> some View {
        
        VStack {
            
            Spacer()
            
            HStack {
                
                Spacer()
                
                ForEach((0..<speedSegmentsCount(for: width)).reversed(), id: \.self) { value in
                    
                    HStack(spacing: 0) {
                        
                        Color.clear
                            .frame(width: CGFloat(value), height: 14)
                        
                        Capsule()
                            .frame(width: 1, height: 14)
                            .foregroundColor(Color(.backPrimary))
                    }
                }
            }
            
        }.padding(5)
    }
}

#Preview {
    ZStack {
        
        Color(.back)
        
        SampleControlView(viewModel: .init(update: Empty().eraseToAnyPublisher()))
            .padding()
    }
}
