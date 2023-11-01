//
//  XCTestCase+MemoryLeaking.swift
//
//
//  Created by Max Gribov on 30.10.2023.
//

import XCTest

extension XCTestCase {
    
    func trackForMemoryLeaks( _ instance: AnyObject, file: StaticString = #filePath, line: UInt = #line) {
        
        addTeardownBlock { [weak instance] in
             
            XCTAssertNil(instance, "Instance should have been deallocated. Potential memory leak", file: file, line: line)
        }
    }
}
