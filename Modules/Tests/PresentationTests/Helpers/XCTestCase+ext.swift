//
//  XCTestCase+ext.swift
//
//
//  Created by Yandex KZ on 02.12.2023.
//

import Foundation
import XCTest
import Domain

extension XCTestCase {
    
    func someLayer(
        id: Layer.ID = Layer.ID(),
        name: String = "Some Layer",
        isPlaying: Bool = false,
        isMuted: Bool = false,
        control: Layer.Control = .initial
    ) -> Layer {
        
        Layer(
            id: id,
            name: name,
            isPlaying: isPlaying,
            isMuted: isMuted,
            control: control
        )
    }
}


