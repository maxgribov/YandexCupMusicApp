//
//  URL+ext.swift
//  YandexCupMusicApp
//
//  Created by Max Gribov on 29.11.2023.
//

import Foundation

extension URL {
    
    static func compositionFileURL() -> URL {
        
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("composition.caf")
    }
}
