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
                .overlay {
                    Image(.guitarIcon)
                }
                .frame(width: 60, height: 60)
            
            VStack(spacing: 0) {
                
                ForEach(viewModel.items) { itemViewModel in
                
                    SampleItemView(viewModel: itemViewModel)
                }
                
            }.background { Color(.backAccent)}
            
            Color.clear
                .frame(width: 60, height :30)
            
        }
        .padding(5)
        .background { Capsule().foregroundColor(Color(.backAccent))}
    }
}

#Preview {
    
    SampleSelectorView(
        viewModel: .init(instrument: .guitar,
                         items: [
            .init(id: "1", name: "sample 1"),
            .init(id: "2", name: "sample 2"),
            .init(id: "3", name: "sample 3")],
                         loadSample: { _ in Empty().eraseToAnyPublisher() }))
}

struct SampleItemView: View {
    
    let viewModel: SampleItemViewModel
    
    var body: some View {
        
        Text(viewModel.name)
            .foregroundColor(Color(.textPrimary))
            .frame(minHeight: 44)
    }
}
