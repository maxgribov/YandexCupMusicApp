//
//  CGSizeCalculationsTests.swift
//  
//
//  Created by Max Gribov on 03.11.2023.
//

import XCTest

extension CGSize {
    
    func offset(translation: CGSize) -> CGSize {
        
        let newOffset = CGSize(width: width + translation.width ,
                               height: height + translation.height)
        
        return newOffset
    }
    
    func limit(area: CGSize) -> CGSize {
        
        let centerX = area.width / 2
        let centerY = area.height / 2
        
        return self
    }
}

final class CGSizeCalculationsTests: XCTestCase {

    func test_offset_expectedResults() {
        
        XCTAssertEqual(CGSize.zero.offset(translation: .zero), .zero)
        XCTAssertEqual(CGSize.zero.offset(translation: .init(width: 100, height: 200)), .init(width: 100, height: 200))
        XCTAssertEqual(CGSize.zero.offset(translation: .init(width: -100, height: -200)), .init(width: -100, height: -200))
        XCTAssertEqual(CGSize(width: 100, height: 100).offset(translation: .init(width: 50, height: 50)), .init(width: 150, height: 150))
        XCTAssertEqual(CGSize(width: 100, height: 100).offset(translation: .init(width: -50, height: -50)), .init(width: 50, height: 50))
    }
}
