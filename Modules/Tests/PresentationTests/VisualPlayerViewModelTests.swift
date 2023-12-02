//
//  VisualPlayerViewModelTests.swift
//  
//
//  Created by Yandex KZ on 02.12.2023.
//

import XCTest
import Combine
import Domain

final class VisualPlayerViewModel: ObservableObject {
    
    @Published private(set) var title: String
    
    init(title: String) {
        self.title = title
    }

}

final class VisualPlayerViewModelTests: XCTestCase {
    
    func test_init_titleEqualTrackName() {
        
        let sut = VisualPlayerViewModel(title: "track name")
        
        XCTAssertEqual(sut.title, "track name")
    }
}
