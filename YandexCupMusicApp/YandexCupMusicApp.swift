//
//  YandexCupMusicAppApp.swift
//  YandexCupMusicApp
//
//  Created by Max Gribov on 30.10.2023.
//

import SwiftUI
import AVFoundation
import Domain
import Processing
import Persistence
import Presentation
import Interface

@main
struct YandexCupMusicApp: App {
    
    let appModel: AppModel = .prod
    
    var body: some Scene {
        
        WindowGroup {
            
            MainView(viewModel: appModel.mainViewModel())
                .background(Color.black.ignoresSafeArea())
        }
    }
}

