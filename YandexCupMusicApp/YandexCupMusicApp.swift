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
    
    let appModel = AppModel(
        producer: Producer(
            player: FoundationPlayer(makePlayer: { data in try AVAudioPlayer(data: data) }),
            recorder: FoundationRecorder(makeRecorder: { url, settings in try AVAudioRecorder(url: url, settings: settings) })),
        localStore: BundleSamplesLocalStore())
    
    var body: some Scene {
        
        WindowGroup {
            
            MainView(viewModel: appModel.mainViewModel())
                .background(Color.black.ignoresSafeArea())
        }
    }
}

extension AVAudioPlayer: AVAudioPlayerProtocol {}
extension AVAudioRecorder: AVAudioRecorderProtocol {}
