//
//  File.swift
//  
//
//  Created by Max Gribov on 26.11.2023.
//

import Foundation

public protocol AVAudioEngineProtocol {
    
    var isRunning: Bool { get }
    func prepare()
    func start() throws
}
