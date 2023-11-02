//
//  SampleSelectorView.swift
//
//
//  Created by Max Gribov on 02.11.2023.
//

import SwiftUI
import Combine
import Presentation

struct SampleSelectorView: View {
    
    @ObservedObject var viewModel: SampleSelectorViewModel
    
    var body: some View {
        
        VStack {
            
            Circle()
                .foregroundColor(Color(.backAccent))
                .overlay { viewModel.instrument.buttonIcon }
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

struct SampleItemView: View {
    
    let viewModel: SampleItemViewModel
    
    var body: some View {
        
        Text(viewModel.name)
            .foregroundColor(Color(.textPrimary))
            .frame(minHeight: 44)
            .padding(.horizontal, 5)
            .background {
                if viewModel.isOdd {
                    Color(.white)
                }
            }
    }
}
