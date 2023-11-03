//
//  LayersUpdate.swift
//  YandexCupMusicApp
//
//  Created by Max Gribov on 04.11.2023.
//

import Foundation
import Domain

struct LayersUpdate: Equatable {
    
    let layers: [Layer]
    let active: Layer.ID?
}
