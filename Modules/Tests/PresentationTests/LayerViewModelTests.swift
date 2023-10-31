//
//  LayerViewModelTests.swift
//
//
//  Created by Max Gribov on 31.10.2023.
//

import XCTest
import Combine

final class LayerViewModel: Identifiable {

    let id: Layer.ID
    let name: String
    @Published private(set) var isPlaying: Bool
    @Published private(set) var isMuted: Bool
    let delegateActionSubject = PassthroughSubject<DelegateAction, Never>()
    
    init(id: Layer.ID, name: String, isPlaying: Bool, isMuted: Bool) {
        
        self.id = id
        self.name = name
        self.isPlaying = isPlaying
        self.isMuted = isMuted
    }
    
    convenience init(with layer: Layer) {
        
        self.init(id: layer.id, name: layer.name, isPlaying: layer.isPlaying, isMuted: layer.isMuted)
    }
    
    func playButtonDidTaped() {
        
        isPlaying.toggle()
        delegateActionSubject.send(.isPlayingDidChanged(isPlaying))
    }
    
    func muteButtonDidTapped() {
        
        isMuted.toggle()
        delegateActionSubject.send(.isMutedDidChanged(isMuted))
    }
    
    func deleteButtonDidTapped() {
        
        delegateActionSubject.send(.deleteLayer(id))
    }
}

extension LayerViewModel {
    
    enum DelegateAction: Equatable {
        
        case isPlayingDidChanged(Bool)
        case isMutedDidChanged(Bool)
        case deleteLayer(Layer.ID)
    }
}

struct Layer {
    
    typealias ID = UUID
    
    let id: ID
    let name: String
    var isPlaying: Bool
    var isMuted: Bool
    var control: Control
    
    struct Control {
        
        let volume: Double
        let speed: Double
    }
}

final class LayerViewModelTests: XCTestCase {
    
    var cancellables = Set<AnyCancellable>()
    
    override func setUp() async throws {
        try await super.setUp()
        
        cancellables = []
    }

    func test_initWitLayer_correctlySetup() {
        
        let layer = Layer(id: UUID(), name: "some layer", isPlaying: true, isMuted: false, control: .init(volume: 0, speed: 0))
        let sut = LayerViewModel(with: layer)
        
        XCTAssertEqual(sut.id, layer.id)
        XCTAssertEqual(sut.name, layer.name)
        XCTAssertEqual(sut.isPlaying, layer.isPlaying)
        XCTAssertEqual(sut.isMuted, layer.isMuted)
    }
    
    func test_playButtonDidTapped_togglesIsPlayingState() {
        
        let sut = makeSUT(isPlaying: false)
        
        sut.playButtonDidTaped()
        
        XCTAssertTrue(sut.isPlaying)
    }
    
    func test_playButtonDidTapped_informDelegateIsPlayingDidChanged() {
        
        let sut = makeSUT(isPlaying: false)
        
        expect(sut, delegateAction: .isPlayingDidChanged(true), for: {
            
            sut.playButtonDidTaped()
        })
    }
    
    func test_muteButtonDidTapped_toggleIsMutedState() {
        
        let sut = makeSUT(isMuted: false)
        
        sut.muteButtonDidTapped()
        
        XCTAssertTrue(sut.isMuted)
    }
    
    func test_muteButtonDidTapped_informsDelegateIsMutedDidChanged() {
        
        let sut = makeSUT(isMuted: false)
        
        expect(sut, delegateAction: .isMutedDidChanged(true), for: {
            
            sut.muteButtonDidTapped()
        })
    }
    
    func test_deleteButtonDidTapped_informDelegateDeleteLayerWithID() {
        
        let sut = makeSUT()
        
        expect(sut, delegateAction: .deleteLayer(sut.id), for: {
            
            sut.deleteButtonDidTapped()
        })
    }
    
    //MARK: - Helpers
    
    private func makeSUT(id: Layer.ID = UUID(), name: String = "", isPlaying: Bool = false, isMuted: Bool = false) -> LayerViewModel {
        
        let sut = LayerViewModel(id: id, name: name, isPlaying: isPlaying, isMuted: isMuted)
        
        return sut
    }

    private func expect(
        _ sut: LayerViewModel,
        delegateAction expectedDelegateAction: LayerViewModel.DelegateAction?,
        for action: () -> Void,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        
        var receivedDelegateAction: LayerViewModel.DelegateAction? = nil
        sut.delegateActionSubject
            .sink { receivedDelegateAction = $0 }
            .store(in: &cancellables)
        
        action()
        
        XCTWaiter().wait(for: [], timeout: 0.01)
        
        XCTAssertEqual(receivedDelegateAction, expectedDelegateAction, "Expected \(String(describing: expectedDelegateAction)), got \(String(describing: receivedDelegateAction)) instead", file: file, line: line)
    }
}
