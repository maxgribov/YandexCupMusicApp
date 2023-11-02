//
//  SampleControlViewModelTests.swift
//  
//
//  Created by Max Gribov on 02.11.2023.
//

import XCTest
import Combine
import Domain

struct SampleControlViewModel {
    
    private(set) var control: Layer.Control?
}

final class SampleControlViewModelTests: XCTestCase {

    func test_init_controlNil() {
        
        let sut = SampleControlViewModel()
        
        XCTAssertNil(sut.control)
    }

}
