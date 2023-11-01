//
//  Player.swift
//  
//
//  Created by Max Gribov on 31.10.2023.
//

import Foundation
import Domain

public protocol Player {
    
    var playing: Set<Layer.ID> { get }
    func play(id: Layer.ID, data: Data, control: Layer.Control)
    func stop(id: Layer.ID)
}