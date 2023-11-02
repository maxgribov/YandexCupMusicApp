//
//  InstrumentSelectorView.swift
//
//
//  Created by Max Gribov on 02.11.2023.
//

import SwiftUI
import Presentation

struct InstrumentSelectorView: View {
    
    let viewModel: InstrumentSelectorViewModel
    
    var body: some View {
        
        HStack {
            
            ForEach(viewModel.buttons) { buttonViewModel in
            
                InstrumentButtonView(viewModel: buttonViewModel) {
                    
                    viewModel.buttonDidTapped(for: buttonViewModel.id)
                }
                
                if buttonViewModel.id != viewModel.buttons.last?.id {
                    
                    Spacer()
                }
            }
        }
    }
}

#Preview {
    
    InstrumentSelectorView(viewModel: .init(buttons: [
        .init(instrument: .guitar),
        .init(instrument: .drums),
        .init(instrument: .brass)]))
    .background {
        Color(.back)
    }
    .frame(width: 320)
    
}
