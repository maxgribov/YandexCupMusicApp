//
//  AVAudioRecorderProtocol.swift
//  
//
//  Created by Max Gribov on 02.11.2023.
//

import AVFoundation

public protocol AVAudioRecorderProtocol: AnyObject {
    
    init(
        url: URL,
        settings: [String : Any]
    ) throws
    
    var delegate: AVAudioRecorderDelegate? { get set }
    
    @discardableResult
    func record() -> Bool
    func stop()
}
