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
    
    var body: some View {
        
        GeometryReader { proxy in
            
            LinearGradient(gradient: Gradient(colors: [Color(.backControl).opacity(0.1), Color(.backControl)]), startPoint: .top, endPoint: .bottom)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay { volumeRulerView(for: proxy.size.height) }
                .overlay { speedRulerView(for: proxy.size.width) }
        }
    }
    
    func volumeSegmentsCount(for height: CGFloat) -> Int {
        
       Int(height / 70)
    }
    
    @ViewBuilder
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
