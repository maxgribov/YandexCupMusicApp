//
//  AVAudioPlayerProtocol.swift
//
//
//  Created by Max Gribov on 01.11.2023.
//

import AVFoundation

public protocol AVAudioPlayerProtocol: AnyObject {
    
    init(data: Data) throws

    var volume: Float { get set }
    var enableRate: Bool { get set }
    var rate: Float { get set }
    var numberOfLoops: Int { get set }
    var currentTime: TimeInterval { get set }
    
    @discardableResult
    func play() -> Bool
    func stop()
}
