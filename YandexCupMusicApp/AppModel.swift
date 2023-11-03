//
//  AppModel.swift
//  YandexCupMusicApp
//
//  Created by Max Gribov on 04.11.2023.
//

import Foundation
import Combine
import Domain
import Processing
import Persistence

final class AppModel<S> where S: SamplesLocalStore {
    
    let producer: Producer
    let localStore: S
    
    init(producer: Producer, localStore: S) {
        
        self.producer = producer
        self.localStore = localStore
    }
}
