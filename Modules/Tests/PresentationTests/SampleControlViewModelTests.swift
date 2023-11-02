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
        
        let sut = makeSUT()
        let controlValueSpy = ValueSpy(sut.$control)
        
        XCTAssertEqual(controlValueSpy.values, [nil])
    }
    
    func test_init_controlValueWithUpdateValue() {
        
        let control = Layer.Control(volume: 1, speed: 1)
        let sut = makeSUT(initial: control)
        let controlValueSpy = ValueSpy(sut.$control)
        
        XCTAssertEqual(controlValueSpy.values, [control])
    }

    func test_isKnobPresented_deliverFalseOnControlNil() {
        
        let sut = makeSUT()
        
        XCTAssertFalse(sut.isKnobPresented)
    }
    
    func test_isKnobPresented_deliverTrueOnControlNotNil() {
        
        let sut = makeSUT(initial: .init(volume: 1, speed: 1))
        
        XCTAssertTrue(sut.isKnobPresented)
    }
    
    func test_knobPosition_deliversZeroOnControlNil() {
        
        let sut = makeSUT()
        
        XCTAssertEqual(sut.knobPosition(for: someSize()), .zero)
    }
    
    //MARK: - Helpers
    
    private func makeSUT(
        initial control: Layer.Control? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> SampleControlViewModel {
        
        let sut = SampleControlViewModel(update: Just(control).eraseToAnyPublisher())
        trackForMemoryLeaks(sut, file: file, line: line)
        
        return sut
    }
    
    private func someSize() -> CGSize {
        .init(width: 100, height: 200)
    }
}
