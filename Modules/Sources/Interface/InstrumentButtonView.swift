//
//  InstrumentButtonView.swift
//
//
//  Created by Max Gribov on 02.11.2023.
//

import SwiftUI
import Presentation
import Domain

struct InstrumentButtonView: View {
    
    let viewModel: InstrumentButtonViewModel
    let action: () -> Void
    
    var body: some View {
        
        Button(action: action) {
            
            VStack {
                
                Circle()
                    .foregroundColor(Color(.backPrimary))
                    .overlay {
                        viewModel.instrument.buttonIcon
                            .resizable()
                    }
                
                Text(viewModel.instrument.name.lowercased())
                    .foregroundColor(Color(.textSecondary))
            }
        }
    }
}

#Preview {
    
    ZStack {
        
        Color(.back)
        
        HStack(spacing: 40) {
            
            InstrumentButtonView(viewModel: .init(instrument: .guitar)){}
            InstrumentButtonView(viewModel: .init(instrument: .drums)){}
            InstrumentButtonView(viewModel: .init(instrument: .brass)){}
        }
    }
}

extension Instrument {
    
    var buttonIcon: Image {
        
        switch self {
        case .guitar: return Image(.guitarIcon)
        case .drums: return Image(.drumsIcon)
        case .brass: return Image(.brassIcon)
        }
    }
}
