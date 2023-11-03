//
//  AppModelTests.swift
//  YandexCupMusicAppTests
//
//  Created by Max Gribov on 03.11.2023.
//

import XCTest
import Combine
import Domain
import Processing

final class AppModel {
    
    func activeLayer() -> AnyPublisher<Layer?, Never> {
        Empty().eraseToAnyPublisher()
    }
}

final class AppModelTests: XCTestCase {

    func test_init_activeLayerDoesNotPublishAnything() {
        
        let sut = AppModel()
        let activeLayerSpy = ValueSpy(sut.activeLayer())
        
        XCTAssertEqual(activeLayerSpy.values, [])
    }

}
