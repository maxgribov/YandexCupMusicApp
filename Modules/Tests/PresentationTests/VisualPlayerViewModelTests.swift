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
    
    private(set) var layerID: Layer.ID
    @Published private(set) var title: String
    @Published private(set) var shapes: [VisualPlayerShapeViewModel]
    
    private let delegateActionSubject = PassthroughSubject<DelegateAction, Never>()
    private let makeShapes: (Layer.ID) -> [VisualPlayerShapeViewModel]
    private var cancellables = Set<AnyCancellable>()
    
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
    
    init(layerID: Layer.ID, title: String, makeShapes: @escaping (Layer.ID) -> [VisualPlayerShapeViewModel], trackUpdates: AnyPublisher<Float, Never>) {
        
        self.layerID = layerID
        self.title = title
        self.shapes = makeShapes(layerID)
        self.makeShapes = makeShapes
        
        trackUpdates
            .sink { [unowned self] update in
                
                shapes.forEach { shape in
                    shape.update(update, area: .zero)
                }
                
            }.store(in: &cancellables)
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

class VisualPlayerShapeViewModel: Identifiable {
    
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
    
    func update(_ data: Float, area: CGRect) {
        
        
    }
}

final class VisualPlayerViewModelTests: XCTestCase {
    
    func test_init_titleCorrectTrackNameAndShapes() {
        
        let shapes = [VisualPlayerShapeViewModel(id: UUID(), name: "some shape", scale: .zero, position: .zero)]
        let sut = makeSUT(title: "track name", makeShapes: { _ in shapes })
        
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
    
    func test_trackUpdates_messagesAllShapesToUpdate() {
        
        let shapes = [VisualPlayerShapeViewModelSpy(id: UUID(), name: "", scale: .zero, position: .zero), VisualPlayerShapeViewModelSpy(id: UUID(), name: "", scale: .zero, position: .zero)]
        let trackUdatesStub = PassthroughSubject<Float, Never>()
        let sut = makeSUT(makeShapes: { _ in shapes }, trackUpdates: trackUdatesStub.eraseToAnyPublisher())
        
        let update: Float = 0.5
        trackUdatesStub.send(update)
        
        XCTAssertEqual(shapes[0].messages, [.update(update, .zero)])
        XCTAssertEqual(shapes[1].messages, [.update(update, .zero)])
    }
    
    //MARK: - Helpers
    
    func makeSUT(
        layerID: Layer.ID = UUID(),
        title: String = "",
        makeShapes: @escaping (Layer.ID) -> [VisualPlayerShapeViewModel] = { _ in [] },
        trackUpdates: AnyPublisher<Float, Never> = Empty().eraseToAnyPublisher(),
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> VisualPlayerViewModel {
        
        let sut = VisualPlayerViewModel(layerID: layerID, title: title, makeShapes: makeShapes, trackUpdates: trackUpdates)
        trackForMemoryLeaks(sut, file: file, line: line)
        
        return sut
    }
    
    private class VisualPlayerShapeViewModelSpy: VisualPlayerShapeViewModel {
        
        private(set) var messages = [Message]()
        
        enum Message: Equatable {
            case update(Float, CGRect)
        }
        
        override func update(_ data: Float, area: CGRect) {
            messages.append(.update(data, area))
        }
    }
}
