//
//  LayerViewModelTests.swift
//
//
//  Created by Max Gribov on 31.10.2023.
//

import XCTest
import Combine
import Domain
import Presentation
import Producer

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
    
    func test_playButtonDidTapped_informDelegateIsPlayingDidChanged() {
        
        let sut = makeSUT(isPlaying: false)
        
        expect(sut, delegateAction: .isPlayingDidChanged(true), for: {
            
            sut.playButtonDidTaped()
        })
    }
    
    func test_muteButtonDidTapped_informsDelegateIsMutedDidChanged() {
        
        let sut = makeSUT(isMuted: false)
        
        expect(sut, delegateAction: .isMutedDidChanged(true), for: {
            
            sut.muteButtonDidTapped()
        })
    }
    
    func test_deleteButtonDidTapped_informDelegateDeleteLayerWithID() {
        
        let sut = makeSUT()
        
        expect(sut, delegateAction: .deleteLayer, for: {
            
            sut.deleteButtonDidTapped()
        })
    }
    
    func test_selectDidTapped_informDelegateToSelectLayerWithID() {
        
        let sut = makeSUT()
        
        expect(sut, delegateAction: .selectLayer, for: {
            
            sut.selectDidTapped()
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
