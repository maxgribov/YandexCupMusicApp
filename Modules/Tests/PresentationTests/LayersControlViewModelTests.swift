//
//  LayersControlViewModelTests.swift
//
//
//  Created by Max Gribov on 31.10.2023.
//

import XCTest
import Presentation
import Combine

final class LayersControlViewModel: ObservableObject {
    
    @Published var layers: [LayerViewModel]
    
    init(initial layers: [LayerViewModel], updates: AnyPublisher<[LayerViewModel], Never>) {
        
        self.layers = layers
        updates.assign(to: &$layers)
    }
}

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
    
    private static func updatesDummy() -> AnyPublisher<[LayerViewModel], Never> {
        
        PassthroughSubject<[LayerViewModel], Never>().eraseToAnyPublisher()
    }
    
    private func someLayerViewModel() -> LayerViewModel {
        
        .init(id: UUID(), name: "some layer", isPlaying: true, isMuted: false, isActive: true)
    }
}

extension LayerViewModel: Equatable {
    
    public static func == (lhs: Presentation.LayerViewModel, rhs: Presentation.LayerViewModel) -> Bool {
        lhs === rhs
    }
}
