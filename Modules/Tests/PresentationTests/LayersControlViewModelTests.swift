//
//  LayersControlViewModelTests.swift
//
//
//  Created by Max Gribov on 31.10.2023.
//

import XCTest
import Presentation
import Samples
import Combine

final class LayersControlViewModel: ObservableObject {
    
    @Published var layers: [LayerViewModel]
    let delegateActionSubject = PassthroughSubject<DelegateAction, Never>()
    
    private var bindings = Set<AnyCancellable>()
    private var layersDelegateBindings = Set<AnyCancellable>()
    
    init(initial layers: [LayerViewModel], updates: AnyPublisher<[LayerViewModel], Never>) {
        
        self.layers = layers
        updates.assign(to: &$layers)
        
        bind()
    }
    
    private func bind() {
        
        $layers
            .sink { [unowned self] layers in
                
                layersDelegateBindings = []
                layers.forEach(bind(layer:))
                
            }.store(in: &bindings)
    }
    
    private func bind(layer: LayerViewModel) {
        
        layer.delegateActionSubject
            .sink { [weak self] delegateAction in
                
                guard let self else { return }
                
                switch delegateAction {
                case let .isPlayingDidChanged(isPlaying):
                    delegateActionSubject.send(.isPlayingDidChanged(layer.id, isPlaying))

                default:
                    break
                }
                
            }.store(in: &layersDelegateBindings)
    }
}

extension LayersControlViewModel {
    
    enum DelegateAction: Equatable {
        
        case isPlayingDidChanged(Layer.ID, Bool)
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
    
    //MARK: - LayerViewModel integration

    func test_isPlayingDidChanged_informDelegateIsPlayingChangedForLayerWithID() {
        
        let sut = makeSUT(initial: [makeLayerViewModel(isPlaying: false),
                                    makeLayerViewModel(isPlaying: true),
                                    makeLayerViewModel(isPlaying: false)])
        let delegateActionSpy = ValueSpy(sut.delegateActionSubject)
        
        sut.layers[2].playButtonDidTaped()
        
        XCTAssertEqual(delegateActionSpy.values, [.isPlayingDidChanged(sut.layers[2].id, true)])
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
    
    private func makeLayerViewModel(id: Layer.ID = UUID(), name: String = "", isPlaying: Bool = false, isMuted: Bool = false, isActive: Bool = false) -> LayerViewModel {
        
        .init(id: id, name: name, isPlaying: isPlaying, isMuted: isMuted, isActive: isActive)
    }
}

extension LayerViewModel: Equatable {
    
    public static func == (lhs: Presentation.LayerViewModel, rhs: Presentation.LayerViewModel) -> Bool {
        lhs === rhs
    }
}
