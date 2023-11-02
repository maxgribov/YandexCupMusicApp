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
        
        guard let control else {
            return .zero
        }
        
        return Self.calculateKnobPosition(with: control, and: size)
    }
}

extension SampleControlViewModel {
    
    static func calculateKnobPosition(with control: Layer.Control, and size: CGSize) -> CGPoint {
        
        let speed = min(max(control.speed, 0), 1)
        let volume = min(max(control.volume, 0), 1)

        let x = CGFloat(size.width * speed)
        let y = CGFloat(size.height * volume)
        
        return .init(x: x, y: y)
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
    
    func test_calculateKnobPosition_expectedResults() {
        
        let sut = SampleControlViewModel.calculateKnobPosition
        
        XCTAssertEqual(sut(.init(volume: 0, speed: 0), .zero), .zero)
        XCTAssertEqual(sut(.init(volume: 0, speed: 0), .init(width: 100, height: 100)), .zero)
        XCTAssertEqual(sut(.init(volume: 1, speed: 1), .zero), .zero)
        XCTAssertEqual(sut(.init(volume: 1, speed: 1), .init(width: 100, height: 100)), .init(x: 100, y: 100))
        XCTAssertEqual(sut(.init(volume: 1, speed: 0), .init(width: 100, height: 100)), .init(x: 0, y: 100))
        XCTAssertEqual(sut(.init(volume: 0, speed: 1), .init(width: 100, height: 100)), .init(x: 100, y: 0))
        XCTAssertEqual(sut(.init(volume: 0.5, speed: 0.5), .init(width: 100, height: 100)), .init(x: 50, y: 50))
        XCTAssertEqual(sut(.init(volume: -1, speed: -1), .init(width: 100, height: 100)), .zero)
        XCTAssertEqual(sut(.init(volume: 10, speed: 10), .init(width: 100, height: 100)), .init(x: 100, y: 100))
    }
    
    func test_knobPosition_deliversExpectedValueOnControlNotNil() {
        
        let sut = makeSUT(initial: .init(volume: 0.3, speed: 0.9))
        
        XCTAssertEqual(sut.knobPosition(for: .init(width: 100, height: 100)), .init(x: 90, y: 30))
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
