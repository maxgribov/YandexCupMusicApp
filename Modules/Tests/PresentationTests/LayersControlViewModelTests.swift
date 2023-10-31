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
        
        updates
            .assign(to: &$layers)
    }
}

final class LayersControlViewModelTests: XCTestCase {

    func test_init_setupInitialLayers() {
        
        let initialLayers = [someLayerViewModel()]
        let sut = LayersControlViewModel(initial: initialLayers, updates: updatesDummy())
        
        XCTAssertEqual(sut.layers, initialLayers)
    }
    
    private func updatesDummy() -> AnyPublisher<[LayerViewModel], Never> {
        
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
