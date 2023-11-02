//
//  SampleControlViewModelTests.swift
//  
//
//  Created by Max Gribov on 02.11.2023.
//

import XCTest
import Combine
import Domain

final class SampleControlViewModel {
    
    @Published private(set) var control: Layer.Control?
    
    init(update: AnyPublisher<Layer.Control?, Never>) {
        
        self.control = nil
        update.assign(to: &$control)
    }
}

final class SampleControlViewModelTests: XCTestCase {
    
    func test_init_controlNilWithUpdateNil() {
        
        let sut = SampleControlViewModel(update: Just(nil).eraseToAnyPublisher())
        let controlValueSpy = ValueSpy(sut.$control)
        
        XCTAssertEqual(controlValueSpy.values, [nil])
    }
    
    func test_init_controlValueWithUpdateValue() {
        
        let sut = SampleControlViewModel(update: Just(.init(volume: 1, speed: 1)).eraseToAnyPublisher())
        let controlValueSpy = ValueSpy(sut.$control)
        
        XCTAssertEqual(controlValueSpy.values, [.init(volume: 1, speed: 1)])
    }

}
