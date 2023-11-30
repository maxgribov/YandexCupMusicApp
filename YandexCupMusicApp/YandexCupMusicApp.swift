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
            player: AudioEnginePlayer(
                engine: AVAudioEngine(),
                makePlayerNode: { data in AudioEnginePlayerNode(with: data) }),
            recorder: FoundationRecorder(
                makeRecorder: { url, format in try AVAudioRecorder(url: url, format: format) },
                mapper: BundleSamplesLocalStore.bufferMapper(url:)),
            composer: AudioEngineComposer(
                engine: AVAudioEngine(),
                makeNode: { track in AudioEnginePlayerNode(with: track.data) },
                makeRecordingFile: { format in try AVAudioFile(forWriting: .compositionFileURL(), settings: format.settings) })),
        localStore: BundleSamplesLocalStore(mapper: BundleSamplesLocalStore.bufferMapper(url:)),
        sessionConfigurator: .init(session: AVAudioSession.sharedInstance()))
    
    var body: some Scene {
        
        WindowGroup {
            
            MainView(viewModel: appModel.mainViewModel())
                .background(Color.black.ignoresSafeArea())
        }
    }
}
