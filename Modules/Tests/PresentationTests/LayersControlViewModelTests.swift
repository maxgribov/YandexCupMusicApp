//
//  LayersControlViewModelTests.swift
//
//
//  Created by Max Gribov on 31.10.2023.
//

import XCTest
import Combine
import Domain
import Presentation

final class LayersControlViewModelTests: XCTestCase {

    func test_init_setupInitialLayers() {
        
        let initialLayers = [someLayerViewModel()]
        let sut = makeSUT(initial: initialLayers)
        
        XCTAssertEqual(sut.layers, initialLayers)
    }
    
    func test_updates_correctlyUpdatesLayers() {
        
        let updatesStub = PassthroughSubject<[LayerViewModel], Never>()
        let sut = makeSUT(updates: updatesStub.eraseToAnyPublisher())
        let layersSpy = ValueSpy(sut.$layers)
        
        let updatedLayers = [someLayerViewModel()]
        updatesStub.send(updatedLayers)
        
        XCTAssertEqual(layersSpy.values, [[], updatedLayers])
    }
    
    //MARK: - LayerViewModel integration

    func test_isPlayingDidChanged_informDelegateIsPlayingChangedForLayerWithID() {
        
        let sut = makeSUT(initial: [makeLayerViewModel(isPlaying: false),
                                    makeLayerViewModel(isPlaying: true),
                                    makeLayerViewModel(isPlaying: false)])
        
        let layerId = sut.layers[2].id
        expect(sut, delegateActions: [.isPlayingDidChanged(layerId, true)], on: {
            
            sut.playButtonDidTaped(for: layerId)
        })
    }
    
    func test_isMutedDidChanged_informDelegateIsMutedChangedForLayerWithID() {
        
        let sut = makeSUT(initial: [makeLayerViewModel(isMuted: false),
                                    makeLayerViewModel(isMuted: true),
                                    makeLayerViewModel(isMuted: false)])
        
        let layerId = sut.layers[1].id
        expect(sut, delegateActions: [.isMutedDidChanged(layerId, false)], on: {
            
            sut.muteButtonDidTapped(for: layerId)
        })
    }
    
    func test_deleteLayer_informDelegateDeleteLayerWithID() {
        
        let sut = makeSUT(initial: [makeLayerViewModel(),
                                    makeLayerViewModel(),
                                    makeLayerViewModel()])
        
        expect(sut, delegateActions: [.deleteLayer(sut.layers[0].id)], on: {
            
            sut.layers[0].deleteButtonDidTapped()
        })
    }
    
    func test_selectLayer_informDelegateDeleteLayerWithID() {
        
        let sut = makeSUT(initial: [makeLayerViewModel(),
                                    makeLayerViewModel(),
                                    makeLayerViewModel()])
        
        expect(sut, delegateActions: [.selectLayer(sut.layers[2].id)], on: {
            
            sut.layers[2].selectDidTapped()
        })
    }
    
    private func makeSUT(
        initial layers: [LayerViewModel] = [],
        updates: AnyPublisher<[LayerViewModel], Never> = LayersControlViewModelTests.updatesDummy(),
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> LayersControlViewModel {
        
        let sut = LayersControlViewModel(initial: layers, updates: updates)
        trackForMemoryLeaks(sut, file: file, line: line)
        
        return sut
    }
    
    private func expect(
        _ sut: LayersControlViewModel,
        delegateActions expectedActions: [LayersControlViewModel.DelegateAction],
        on action: () -> Void,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        
        let delegateActionSpy = ValueSpy(sut.delegateAction)
        action()
        XCTAssertEqual(delegateActionSpy.values, expectedActions, file: file, line: line)
    }
    
    private static func updatesDummy() -> AnyPublisher<[LayerViewModel], Never> {
        
        PassthroughSubject<[LayerViewModel], Never>().eraseToAnyPublisher()
    }
    
    private func someLayerViewModel() -> LayerViewModel {
        
        .init(id: UUID(), name: "some layer", isPlaying: true, isMuted: false, isActive: true)
    }
    
    private func makeLayerViewModel(id: Layer.ID = UUID(), name: String = "", isPlaying: Bool = false, isMuted: Bool = false, isActive: Bool = false) -> LayerViewModel {
        
        .init(id: id, name: name, isPlaying: isPlaying, isMuted: isMuted, isActive: isActive)
    }
}

extension LayerViewModel: Equatable {
    
    public static func == (lhs: Presentation.LayerViewModel, rhs: Presentation.LayerViewModel) -> Bool {
        lhs.id == rhs.id && lhs.isPlaying == rhs.isPlaying && lhs.isMuted == rhs.isMuted && lhs.isActive == rhs.isActive
    }
}
