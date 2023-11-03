//
//  SampleControlViewModelTests.swift
//  
//
//  Created by Max Gribov on 02.11.2023.
//

import XCTest
import Combine
import Domain
import Presentation

final class SampleControlViewModelTests: XCTestCase {
    
    var cancellables = Set<AnyCancellable>()
    
    override func setUp() async throws {
        try await super.setUp()
        
        cancellables = []
    }
    
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
        
        XCTAssertEqual(sut.knobOffset(in: someSize()), .zero)
    }
    
    func test_calculateKnobOffset_expectedResults() {
        
        let sut = SampleControlViewModel.calculateKnobOffset
        
        XCTAssertEqual(sut(.init(volume: 0, speed: 0), .zero), .zero)
        XCTAssertEqual(sut(.init(volume: 0, speed: 0), .init(width: 100, height: 100)), .init(width: -50, height: -50))
        XCTAssertEqual(sut(.init(volume: 1, speed: 1), .zero), .zero)
        XCTAssertEqual(sut(.init(volume: 1, speed: 1), .init(width: 100, height: 100)), .init(width: 50, height: 50))
        XCTAssertEqual(sut(.init(volume: 1, speed: 0), .init(width: 100, height: 100)), .init(width: -50, height: 50))
        XCTAssertEqual(sut(.init(volume: 0, speed: 1), .init(width: 100, height: 100)), .init(width: 50, height: -50))
        XCTAssertEqual(sut(.init(volume: 0.5, speed: 0.5), .init(width: 100, height: 100)), .init(width: 0, height: 0))
        XCTAssertEqual(sut(.init(volume: -1, speed: -1), .init(width: 100, height: 100)), .init(width: -50, height: -50))
        XCTAssertEqual(sut(.init(volume: 10, speed: 10), .init(width: 100, height: 100)), .init(width: 50, height: 50))
    }
    
    func test_knobOffset_deliversExpectedValueOnControlNotNil() {
        
        let sut = makeSUT(initial: .init(volume: 0.3, speed: 0.9))
        
        XCTAssertEqual(sut.knobOffset(in: .init(width: 100, height: 100)), .init(width: 40, height: -20))
    }
    
    func test_knobPositionDidChanged_doesNotInformDelegateOnControlNil() {
        
        let sut = makeSUT()
        let delegateActionSpy = ValueSpy(sut.delegateAction)
        
        sut.knobPositionDidChanged(position: .init(x: 100, y: 100), size: .init(width: 100, height: 100))
        
        XCTAssertEqual(delegateActionSpy.values, [])
    }
    
    func test_calculateControl_expectedResults() {
        
        let sut = SampleControlViewModel.calculateControl
        
        XCTAssertEqual(sut(.zero, .zero), .init(volume: 0, speed: 0))
        XCTAssertEqual(sut(.init(x: 100, y: 100), .zero), .init(volume: 0, speed: 0))
        XCTAssertEqual(sut(.zero, .init(width: 100, height: 100)), .init(volume: 0, speed: 0))
        XCTAssertEqual(sut(.init(x: 50, y: 50), .init(width: 100, height: 100)), .init(volume: 0.5, speed: 0.5))
        XCTAssertEqual(sut(.init(x: 30, y: 70), .init(width: 100, height: 100)), .init(volume: 0.7, speed: 0.3))
        
        XCTAssertEqual(sut(.init(x: -50, y: -50), .init(width: 100, height: 100)), .init(volume: 0, speed: 0))
        XCTAssertEqual(sut(.init(x: 50, y: 50), .init(width: -100, height: -100)), .init(volume: 0, speed: 0))
    }
    
    func test_knobPositionDidChanged_informDelegateWithPositionDidChangeActionOnControlNotNil() {
        
        let sut = makeSUT(initial: .init(volume: 0.5, speed: 0.7))
        let delegateActionSpy = ValueSpy(sut.delegateAction)
        
        sut.knobPositionDidChanged(position: .init(x: 100, y: 100), size: .init(width: 100, height: 100))

        XCTAssertEqual(delegateActionSpy.values, [.controlDidUpdated(.init(volume: 1, speed: 1))])
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
