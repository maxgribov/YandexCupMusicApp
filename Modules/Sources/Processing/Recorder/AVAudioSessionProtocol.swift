//
//  AVAudioSessionProtocol.swift
//
//
//  Created by Max Gribov on 02.11.2023.
//

import AVFoundation

#if os(iOS)
public protocol AVAudioSessionProtocol: AnyObject {
    
    func setCategory(
        _ category: AVAudioSession.Category,
        mode: AVAudioSession.Mode,
        options: AVAudioSession.CategoryOptions
    ) throws
    
    func setActive(
        _ active: Bool,
        options: AVAudioSession.SetActiveOptions
    ) throws
    
    func requestRecordPermission(
        _ response: @escaping (
            Bool
        ) -> Void
    )
}
#endif
