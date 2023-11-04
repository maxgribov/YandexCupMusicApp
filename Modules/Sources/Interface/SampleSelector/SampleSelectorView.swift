//
//  SampleSelectorView.swift
//
//
//  Created by Max Gribov on 02.11.2023.
//

import SwiftUI
import Combine
import Presentation

public struct SampleSelectorView: View {
    
    @ObservedObject var viewModel: SampleSelectorViewModel
    
    public init(viewModel: SampleSelectorViewModel) {
        
        self.viewModel = viewModel
    }
    
    public var body: some View {
        
        VStack {
            
            Circle()
                .foregroundColor(Color(.backAccent))
                .overlay { buttonIcon }
                .frame(width: 60, height: 60)
            
            VStack(spacing: 0) {
                
                ForEach(viewModel.items) { itemViewModel in
                
                    Button(action: {
                        
                        viewModel.itemDidSelected(for: itemViewModel.id)
                        
                    }, label: {
                        
                        SampleItemView(viewModel: itemViewModel)
                    })
                }
                
            }.background { Color(.backAccent)}
            
            Color.clear
                .overlay {
                    
                    if viewModel.isSampleLoading {
                        ProgressView().offset(y: -10)
                    }
                }
                .frame(width: 60, height : 30)
            
        }.background { Capsule().foregroundColor(Color(.backAccent))}
    }
    
    var buttonIcon: Image {
        
        switch viewModel.instrument {
        case .guitar: return Image(.iconGuitar)
        case .drums: return Image(.iconDrums)
        case .brass: return Image(.iconBrass)
        }
    }
}

#Preview {
    
    SampleSelectorView(
        viewModel: .init(
            instrument: .brass,
            items: [
                .init(id: "1", name: "sample 1", isOdd: false),
                .init(id: "2", name: "sample 2", isOdd: true),
                .init(id: "3", name: "sample 3", isOdd: false)],
            loadSample: { _ in Empty().eraseToAnyPublisher() }))
}
