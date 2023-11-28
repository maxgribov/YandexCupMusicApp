//
//  XCTestCase+ext.swift
//
//
//  Created by Max Gribov on 25.11.2023.
//

import XCTest
import Domain
import Processing
import AVFoundation

extension XCTestCase {
    
    func anyLayerID() -> Layer.ID { UUID() }
    func anyData() -> Data { Data(UUID().uuidString.utf8) }
    
    func makeBundleFileDataStub() -> (data: Data, url: URL)? {
        
        let bundle = Bundle.module
        
        guard let path = bundle.resourcePath else {
            return nil
        }
        
        let filePath = path + "/guitar_01.m4a"
        let url = URL(filePath: filePath)
        
        guard let data = FoundationRecorder<AVAudioRecorder>.bufferMapper(url: url) else {
            return nil
        }
        
        return (data, url)
    }
    
    func anyURL() -> URL {
    
        URL(string: "www.any-url.com")!
    }
    
    func anyNSError() -> NSError {
        
        NSError(domain: "", code: 0)
    }
}

extension AVAudioRecorder: AVAudioRecorderProtocol {}
