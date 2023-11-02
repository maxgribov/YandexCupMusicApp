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
    private let delegateActionSubject = PassthroughSubject<DelegateAction, Never>()
    
    init(update: AnyPublisher<Layer.Control?, Never>) {
        
        self.control = nil
        update.assign(to: &$control)
    }
    
    var delegateAction: AnyPublisher<DelegateAction, Never> {
        
        delegateActionSubject.eraseToAnyPublisher()
    }
    
    var isKnobPresented: Bool { control != nil }
    
    func knobPosition(for size: CGSize) -> CGPoint {
        
        guard let control else {
            return .zero
        }
        
        return Self.calculateKnobPosition(with: control, and: size)
    }
    
    func knobPositionDidChanged(position: CGPoint, size: CGSize) {
        
        guard control != nil else {
            return
        }
        
        let controlUpdate = Self.calculateControl(forKnobPosition: position, and: size)
        delegateActionSubject.send(.controlDidUpdated(controlUpdate))
    }
}

extension SampleControlViewModel {
    
    enum DelegateAction: Equatable {
        
        case controlDidUpdated(Layer.Control)
    }
    
    static func calculateKnobPosition(with control: Layer.Control, and size: CGSize) -> CGPoint {
        
        let volume = min(max(control.volume, 0), 1)
        let speed = min(max(control.speed, 0), 1)

        let x = CGFloat(size.width * speed)
        let y = CGFloat(size.height * volume)
        
        return .init(x: x, y: y)
    }
    
    static func calculateControl(forKnobPosition position: CGPoint, and size: CGSize) -> Layer.Control {
        
        let volume = Double(size.height / position.y)
        let speed = Double(size.width / position.x)
        
        return .init(volume: volume, speed: speed)
    }
}

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
    
    func test_knobPositionDidChanged_doesNotInformDelegateOnControlNil() {
        
        let sut = makeSUT()
        let delegateActionSpy = ValueSpy(sut.delegateAction)
        
        sut.knobPositionDidChanged(position: .init(x: 100, y: 100), size: .init(width: 100, height: 100))
        
        XCTAssertEqual(delegateActionSpy.values, [])
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
