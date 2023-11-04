//
//  InstrumentButtonView.swift
//
//
//  Created by Max Gribov on 02.11.2023.
//

import SwiftUI
import Presentation

struct InstrumentButtonView: View {
    
    let viewModel: InstrumentButtonViewModel
    let tapAction: () -> Void
    let longTapAction: () -> Void
    
    var body: some View {
        
        VStack {
            
            Circle()
                .foregroundColor(Color(.backPrimary))
                .overlay { icon }
                .frame(width: 60, height: 60)
            
            Text(viewModel.instrument.name.lowercased())
                .foregroundColor(Color(.textSecondary))
        }
        .onTapGesture { tapAction() }
        .onLongPressGesture { longTapAction() }
    }
    
    var icon: Image {
        
        switch viewModel.instrument {
        case .guitar: return Image(.iconGuitar)
        case .drums: return Image(.iconDrums)
        case .brass: return Image(.iconBrass)
        }
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

