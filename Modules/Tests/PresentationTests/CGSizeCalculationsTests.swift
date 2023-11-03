//
//  CGSizeCalculationsTests.swift
//  
//
//  Created by Max Gribov on 03.11.2023.
//

import XCTest
import Presentation

final class CGSizeCalculationsTests: XCTestCase {

    func test_offset_expectedResults() {
        
        XCTAssertEqual(CGSize.zero.offset(translation: .zero), .zero)
        XCTAssertEqual(CGSize.zero.offset(translation: .init(width: 100, height: 200)), .init(width: 100, height: 200))
        XCTAssertEqual(CGSize.zero.offset(translation: .init(width: -100, height: -200)), .init(width: -100, height: -200))
        XCTAssertEqual(CGSize(width: 100, height: 100).offset(translation: .init(width: 50, height: 50)), .init(width: 150, height: 150))
        XCTAssertEqual(CGSize(width: 100, height: 100).offset(translation: .init(width: -50, height: -50)), .init(width: 50, height: 50))
    }
    
    func test_limit_expectedResults() {
        
        XCTAssertEqual(CGSize.zero.limit(area: .zero), .zero)
        XCTAssertEqual(CGSize.zero.limit(area: .init(width: 100, height: 100)), .zero)
        XCTAssertEqual(CGSize(width: 50, height: 50).limit(area: .init(width: 100, height: 100)), .init(width: 50, height: 50))
        XCTAssertEqual(CGSize(width: 100, height: 100).limit(area: .init(width: 100, height: 100)), .init(width: 50, height: 50))
        XCTAssertEqual(CGSize(width: -50, height: -50).limit(area: .init(width: 100, height: 100)), .init(width: -50, height: -50))
        XCTAssertEqual(CGSize(width: -100, height: -100).limit(area: .init(width: 100, height: 100)), .init(width: -50, height: -50))
    }
}
