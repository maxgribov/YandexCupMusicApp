//
//  SampleSelectorContainerView.swift
//  YandexCupMusicApp
//
//  Created by Max Gribov on 04.11.2023.
//

import SwiftUI
import Combine
import Presentation
import Interface

struct SampleSelectorContainerView: View {
    
    let viewModel: SampleSelectorViewModel
    let dismissAction: () -> Void
    
    var body: some View {
        
        ZStack {
            
            Color.black
                .opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture(perform: dismissAction)
            
            VStack {
                
                HStack {
                    switch viewModel.instrument {
                    case .guitar:
                        SampleSelectorView(viewModel: viewModel)
                        Spacer()
                        
                    case .drums:
                        SampleSelectorView(viewModel: viewModel)
                        
                    case .brass:
                        Spacer()
                        SampleSelectorView(viewModel: viewModel)
                    }
                }
                
                Spacer()
            }
        }
    }
}

#Preview {
    SampleSelectorContainerView(
        viewModel: .init(
            instrument: .guitar,
            items: [.init(id: "1", name: "sample 1", isOdd: false),
                    .init(id: "2", name: "sample 2", isOdd: true),
                    .init(id: "3", name: "sample 3", isOdd: false)],
            loadSample: { _ in Empty().eraseToAnyPublisher() }),
        dismissAction: {})
}
