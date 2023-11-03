//
//  SampleItemView.swift
//  
//
//  Created by Max Gribov on 02.11.2023.
//

import SwiftUI
import Presentation

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

#Preview {
    
    SampleItemView(viewModel: .init(id: "1", name: "sample 1", isOdd: false))
}
