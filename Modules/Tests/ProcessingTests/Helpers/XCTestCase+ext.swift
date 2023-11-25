//
//  XCTestCase+ext.swift
//
//
//  Created by Max Gribov on 25.11.2023.
//

import XCTest
import Domain

extension XCTestCase {
    
    func anyLayerID() -> Layer.ID { UUID() }
    func anyData() -> Data { Data(UUID().uuidString.utf8) }
}
