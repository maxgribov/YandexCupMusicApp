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

fileprivate extension AppModel where S == BundleSamplesLocalStore, C == AVAudioSession {
    
    static let prod = AppModel(
        producer: Producer(
            player: AudioEnginePlayer(engine: AVAudioEngine(), makePlayerNode: { data in AudioEnginePlayerNode(with: data) }),
            recorder: FoundationRecorder(makeRecorder: { url, format in try AVAudioRecorder(url: url, format: format) }, mapper: BundleSamplesLocalStore.bufferMapper(url:))),
        localStore: BundleSamplesLocalStore(mapper: BundleSamplesLocalStore.bufferMapper(url:)),
        sessionConfigurator: .init(session: AVAudioSession.sharedInstance()))
}
