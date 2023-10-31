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
    @Published private(set) var isActive: Bool
    
    let delegateActionSubject = PassthroughSubject<DelegateAction, Never>()
    
    init(id: Layer.ID, name: String, isPlaying: Bool, isMuted: Bool, isActive: Bool) {
        
        self.id = id
        self.name = name
        self.isPlaying = isPlaying
        self.isMuted = isMuted
        self.isActive = isActive
    }
    
    convenience init(with layer: Layer, isActive: Bool) {
        
        self.init(id: layer.id, name: layer.name, isPlaying: layer.isPlaying, isMuted: layer.isMuted, isActive: isActive)
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
    
    func selectDidTapped() {
        
        delegateActionSubject.send(.selectLayer(id))
    }
    
    func update(isPlaying: Bool) {
        
        self.isPlaying = isPlaying
    }
    
    func update(isActive: Bool) {
        
        self.isActive = isActive
    }
}

extension LayerViewModel {
    
    enum DelegateAction: Equatable {
        
        case isPlayingDidChanged(Bool)
        case isMutedDidChanged(Bool)
        case deleteLayer(Layer.ID)
        case selectLayer(Layer.ID)
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
        let sut = LayerViewModel(with: layer, isActive: true)
        
        XCTAssertEqual(sut.id, layer.id)
        XCTAssertEqual(sut.name, layer.name)
        XCTAssertEqual(sut.isPlaying, layer.isPlaying)
        XCTAssertEqual(sut.isMuted, layer.isMuted)
        XCTAssertEqual(sut.isActive, true)
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
    
    func test_selectDidTapped_informDelegateToSelectLayerWithID() {
        
        let sut = makeSUT()
        
        expect(sut, delegateAction: .selectLayer(sut.id), for: {
            
            sut.selectDidTapped()
        })
    }
    
    func test_updateIsPlaying_updatesIsPlayingState() {
        
        let sut = makeSUT(isPlaying: true)
        
        sut.update(isPlaying: false)
        
        XCTAssertFalse(sut.isPlaying)
    }
    
    func test_updateIsPlaying_doesNotInformDelegate() {
        
        let sut = makeSUT(isPlaying: true)
        
        expect(sut, delegateAction: nil, for: {
            
            sut.update(isPlaying: false)
        })
    }
    
    func test_updateIsActive_updatesIsActiveState() {
        
        let sut = makeSUT(isActive: true)
        
        sut.update(isActive: false)
        
        XCTAssertFalse(sut.isActive)
    }
    
    func test_updateIsActive_doesNotInformDelegate() {
        
        let sut = makeSUT(isActive: true)
        
        expect(sut, delegateAction: nil, for: {
            
            sut.update(isActive: false)
        })
    }
    
    //MARK: - Helpers
    
    private func makeSUT(id: Layer.ID = UUID(), name: String = "", isPlaying: Bool = false, isMuted: Bool = false, isActive: Bool = true) -> LayerViewModel {
        
        let sut = LayerViewModel(id: id, name: name, isPlaying: isPlaying, isMuted: isMuted, isActive: isActive)
        
        return sut
    }

    private func expect(
        _ sut: LayerViewModel,
        delegateAction expectedDelegateAction: LayerViewModel.DelegateAction?,
        for action: () -> Void,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        
        let delegateSpy = ValueSpy(sut.delegateActionSubject)
        
        action()
        
        XCTWaiter().wait(for: [], timeout: 0.01)
        
        if let expectedDelegateAction {
            
            XCTAssertEqual(delegateSpy.values, [expectedDelegateAction], "Expected action: \(expectedDelegateAction), got \(delegateSpy.values) instead", file: file, line: line)
            
        } else {
            
            XCTAssertTrue(delegateSpy.values.isEmpty, "Expected no actions, got \(delegateSpy.values) instead", file: file, line: line)
        }
    }
}
