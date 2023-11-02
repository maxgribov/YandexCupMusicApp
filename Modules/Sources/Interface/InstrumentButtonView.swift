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
    let tapAction: () -> Void
    let longTapAction: () -> Void
    
    var body: some View {
        
        VStack {
            
            Circle()
                .foregroundColor(Color(.backPrimary))
                .overlay {
                    viewModel.instrument.buttonIcon
                }
                .frame(width: 60, height: 60)
            
            Text(viewModel.instrument.name.lowercased())
                .foregroundColor(Color(.textSecondary))
        }
        .onTapGesture { tapAction() }
        .onLongPressGesture { longTapAction() }
    }
}

#Preview {
    
    ZStack {
        
        Color(.back)
        
        HStack(spacing: 40) {
            
            InstrumentButtonView(viewModel:  .init(instrument: .guitar), tapAction: {}, longTapAction: {})
            InstrumentButtonView(viewModel: .init(instrument: .drums), tapAction: {}, longTapAction: {})
            InstrumentButtonView(viewModel: .init(instrument: .brass), tapAction: {}, longTapAction: {})
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
