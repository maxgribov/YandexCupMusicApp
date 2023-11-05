//
//  SoundWaveProgressView.swift
//
//
//  Created by Max Gribov on 03.11.2023.
//

import SwiftUI

public struct SoundWaveProgressView: View {

    @Binding var progress: Double
    
    public init(progress: Binding<Double>) {
        
        self._progress = progress
    }
    
    public var body: some View {
        
        GeometryReader { proxy in
            
            SoundWaveView(size: proxy.size)
            .overlay {
                
                ProgressMaskView(progress: $progress, width: proxy.size.width)
                    .blendMode(.multiply)
            }
        }
    }
}

#Preview {
    
    ZStack {
        
        Color(.black)
        
        SoundWaveProgressView(progress: .constant(0.6))
            .frame(height: 50)
            .padding()
    }
}

extension SoundWaveProgressView {
    
    struct SoundWaveView: View {
        
        let size: CGSize
        var elements: Int { Int(size.width / 4) }
        
        var body: some View {
            
            HStack(spacing: 2) {
                ForEach(0..<elements, id: \.self) { _ in
                    
                    Capsule()
                        .foregroundStyle(Color(white: 1))
                        .frame(width: 2, height: randomHeight(for: size.height))
                }
            }
        }
        
        func randomHeight(for height: CGFloat) -> CGFloat {
            
            let min = height / 3
            let max = height
            
            return CGFloat.random(in: min..<max)
        }
    }
    
    struct ProgressMaskView: View {
        
        @Binding var progress: Double
        let width: CGFloat
        
        var body: some View {
            
            Color.green
                .frame(width: CGFloat(width * progress))
                .offset(x: progressMaskOffset(for: width))
                .blendMode(.multiply)
        }
        
        func progressMaskOffset(for width: CGFloat) -> CGFloat {
            
            -CGFloat((width * (1 - progress)) / 2)
        }
    }
}
