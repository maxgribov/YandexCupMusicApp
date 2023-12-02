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
    @Published private(set) var shapes: [VisualPlayerShapeViewModel]
    
    private let delegateActionSubject = PassthroughSubject<DelegateAction, Never>()
    
    enum DelegateAction: Equatable {
        
        case dismiss
        case togglePlay
        case rewind
        case fastForward
        case export
    }
    
    var delegateAction: AnyPublisher<DelegateAction, Never> {
        
        delegateActionSubject.eraseToAnyPublisher()
    }
    
    init(title: String, shapes: [VisualPlayerShapeViewModel]) {
        
        self.title = title
        self.shapes = shapes
    }
    
    func backButtonDidTapped() {
        
        delegateActionSubject.send(.dismiss)
    }
    
    func playButtonDidTapped() {
        
        delegateActionSubject.send(.togglePlay)
    }
    
    func rewindButtonDidTapped() {
        
        delegateActionSubject.send(.rewind)
    }
    
    func fastForwardButtonDidTapped() {
        
        delegateActionSubject.send(.fastForward)
    }

    func exportButtonDidTapped() {
        
        delegateActionSubject.send(.export)
    }
    
}

final class VisualPlayerShapeViewModel: Identifiable {
    
    let id: UUID
    let name: String
    @Published var scale: CGFloat
    @Published var position: CGPoint
    
    init(id: UUID, name: String, scale: CGFloat, position: CGPoint) {
        
        self.id = id
        self.name = name
        self.scale = scale
        self.position = position
    }
}

final class VisualPlayerViewModelTests: XCTestCase {
    
    func test_init_titleCorrectTrackNameAndShapes() {
        
        let shapes = [VisualPlayerShapeViewModel(id: UUID(), name: "some shape", scale: .zero, position: .zero)]
        let sut = makeSUT(title: "track name", shapes: shapes)
        
        XCTAssertEqual(sut.title, "track name")
        XCTAssertEqual(sut.shapes[0].id, shapes[0].id)
    }
    
    func test_backButtonDidTap_messgesDelegateToDissmiss() {
        
        let sut = makeSUT()
        let delegateActionSpy = ValueSpy(sut.delegateAction)
        
        sut.backButtonDidTapped()
        
        XCTAssertEqual(delegateActionSpy.values, [.dismiss])
    }
    
    func test_playButtonDidTaped_messagesDelegateToTogglePlay() {
        
        let sut = makeSUT()
        let delegateActionSpy = ValueSpy(sut.delegateAction)
        
        sut.playButtonDidTapped()
        
        XCTAssertEqual(delegateActionSpy.values, [.togglePlay])
    }
    
    func test_rewindButtonDidTaped_messagesDelegateToRewind() {
        
        let sut = makeSUT()
        let delegateActionSpy = ValueSpy(sut.delegateAction)
        
        sut.rewindButtonDidTapped()
        
        XCTAssertEqual(delegateActionSpy.values, [.rewind])
    }
    
    func test_fastForwardButtonDidTaped_messagesDelegateToFastForward() {
        
        let sut = makeSUT()
        let delegateActionSpy = ValueSpy(sut.delegateAction)
        
        sut.fastForwardButtonDidTapped()
        
        XCTAssertEqual(delegateActionSpy.values, [.fastForward])
    }
    
    func test_exportForwardButtonDidTaped_messagesDelegateToExport() {
        
        let sut = makeSUT()
        let delegateActionSpy = ValueSpy(sut.delegateAction)
        
        sut.exportButtonDidTapped()
        
        XCTAssertEqual(delegateActionSpy.values, [.export])
    }
    
    //MARK: - Helpers
    
    func makeSUT(
        title: String = "",
        shapes: [VisualPlayerShapeViewModel] = [],
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> VisualPlayerViewModel {
        
        let sut = VisualPlayerViewModel(title: title, shapes: shapes)
        trackForMemoryLeaks(sut, file: file, line: line)
        
        return sut
    }
}
