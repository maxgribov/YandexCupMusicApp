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
    
    var isKnobPresented: Bool { control != nil }
    
    func knobPosition(for size: CGSize) -> CGPoint {
        
        .zero
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

    func test_isKnobPresented_deliverFalseOnControlNil() {
        
        let sut = SampleControlViewModel(update: Just(nil).eraseToAnyPublisher())
        
        XCTAssertFalse(sut.isKnobPresented)
    }
    
    func test_isKnobPresented_deliverTrueOnControlNotNil() {
        
        let sut = SampleControlViewModel(update: Just(.init(volume: 1, speed: 1)).eraseToAnyPublisher())
        
        XCTAssertTrue(sut.isKnobPresented)
    }
    
    func test_knobPosition_deliversZeroOnControlNil() {
        
        let sut = SampleControlViewModel(update: Just(nil).eraseToAnyPublisher())
        
        XCTAssertEqual(sut.knobPosition(for: someSize()), .zero)
    }
    
    //MARK: - Helpers
    
    private func someSize() -> CGSize {
        .init(width: 100, height: 200)
    }
}
