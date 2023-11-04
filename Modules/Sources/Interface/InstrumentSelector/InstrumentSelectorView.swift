//
//  InstrumentSelectorView.swift
//
//
//  Created by Max Gribov on 02.11.2023.
//

import SwiftUI
import Presentation

public struct InstrumentSelectorView: View {
    
    let viewModel: InstrumentSelectorViewModel
    
    public init(viewModel: InstrumentSelectorViewModel) {
        
        self.viewModel = viewModel
    }
    
    public var body: some View {
        
        HStack {
            
            ForEach(viewModel.buttons) { buttonViewModel in
            
                InstrumentButtonView(viewModel: buttonViewModel,
                                     tapAction: { viewModel.buttonDidTapped(for: buttonViewModel.id)},
                                     longTapAction: { viewModel.buttonDidLongTapped(for: buttonViewModel.id)})
                
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
