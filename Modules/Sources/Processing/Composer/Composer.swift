//
//  File.swift
//  
//
//  Created by Max Gribov on 29.11.2023.
//

import Foundation
import Combine

public protocol Composer {
    
    func compose(tracks: [Track]) -> AnyPublisher<URL, ComposerError>
    func stop()
}
