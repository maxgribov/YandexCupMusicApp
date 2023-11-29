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

fileprivate extension AppModel where S == BundleSamplesLocalStore,
                                     A == AVAudioSession,
                                     P == AudioEnginePlayer<AudioEnginePlayerNode>,
                                     R == FoundationRecorder<AVAudioRecorder>,
                                     C == AudioEngineComposer<AudioEnginePlayerNode> {
    
    static let prod = AppModel(
        producer: Producer(
            player: AudioEnginePlayer(engine: AVAudioEngine(), makePlayerNode: { data in AudioEnginePlayerNode(with: data) }),
            recorder: FoundationRecorder(makeRecorder: { url, format in try AVAudioRecorder(url: url, format: format) }, mapper: BundleSamplesLocalStore.bufferMapper(url:)),
            composer: AudioEngineComposer(
                engine: AVAudioEngine(),
                makeNode: { track in AudioEnginePlayerNode(with: track.data) },
                makeRecordingFile: { format in try AVAudioFile(forWriting: URL.compositionFileURL(), settings: format.settings)})),
        localStore: BundleSamplesLocalStore(mapper: BundleSamplesLocalStore.bufferMapper(url:)),
        sessionConfigurator: .init(session: AVAudioSession.sharedInstance()))
}

extension URL {
    
    static func compositionFileURL() -> URL {
        
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("composition.m4a")
    }
}
