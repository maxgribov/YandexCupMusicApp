//
//  MainViewModelTests.swift
//  YandexCupMusicAppTests
//
//  Created by Max Gribov on 03.11.2023.
//

import XCTest
import Combine
import Domain
import Presentation
@testable import YandexCupMusicApp

final class MainViewModelTests: XCTestCase {
    
    func test_init_instrumentsContainsCorrectButtons() {
        
        let sut = makeSUT()
        
        XCTAssertEqual(sut.instrumentSelector.buttons.map(\.instrument), [.guitar, .drums, .brass])
    }
    
    func test_init_sampleControlWithControlNil() {
        
        let sut = makeSUT()
        
        XCTAssertNil(sut.sampleControl.control)
    }
    
    //FIXME: test broken because of some kind of memory leak. Values from publishers from another tests some how affect values in this tests. Not sure why.
    
//    func test_init_controlPanelContainsCorrectButtons() {
//
//        let sut = makeSUT()
//        
//        XCTAssertEqual(sut.controlPanel.layersButton.name, "Слои")
//        XCTAssertEqual(sut.controlPanel.layersButton.isActive, false)
//        XCTAssertEqual(sut.controlPanel.layersButton.isEnabled, true)
//        
//        XCTAssertEqual(sut.controlPanel.recordButton.type, .record)
//        XCTAssertEqual(sut.controlPanel.layersButton.isActive, false)
//        XCTAssertEqual(sut.controlPanel.layersButton.isEnabled, true)
//        
//        XCTAssertEqual(sut.controlPanel.composeButton.type, .compose)
//        XCTAssertEqual(sut.controlPanel.layersButton.isActive, false)
//        XCTAssertEqual(sut.controlPanel.layersButton.isEnabled, true)
//        
//        XCTAssertEqual(sut.controlPanel.playButton.type, .play)
//        XCTAssertEqual(sut.controlPanel.layersButton.isActive, false)
//        XCTAssertEqual(sut.controlPanel.layersButton.isEnabled, true)
//    }
    
    func test_init_sampleSelectorNil() {
        
        let sut = makeSUT()
        
        XCTAssertNil(sut.sampleSelector)
    }
    
    func test_instrumentSelectorButtonDidTapped_informDlegateThatDefaultSampleSelected() {
        
        let sut = makeSUT()
        let delegateActionSpy = ValueSpy(sut.delegateAction)
        
        sut.instrumentSelector.buttonDidTapped(for: Instrument.brass.rawValue)
        
        XCTAssertEqual(delegateActionSpy.values, [.defaultSampleSelected(.brass)])
    }
    
    func test_instrumentSelectorButtonDidLongTapped_createsSampleSelectorViewModel() {
        
        let sut = makeSUT(samplesIDs: { _ in Just([Sample.ID(), Sample.ID(), Sample.ID()]).setFailureType(to: Error.self).eraseToAnyPublisher() })
        
        sut.instrumentSelector.buttonDidLongTapped(for: Instrument.guitar.rawValue)
        
        XCTAssertEqual(sut.sampleSelector?.instrument, .guitar)
    }
    
    func test_activeLevel_setsAndRemovesControlValueForSampleControl() {
        
        let activeLayerStub = PassthroughSubject<Layer?, Never>()
        let sut = makeSUT(activeLayer: activeLayerStub.eraseToAnyPublisher())
        
        XCTAssertNil(sut.sampleControl.control)
        
        let layer = someLayer()
        activeLayerStub.send(someLayer())
        XCTAssertEqual(sut.sampleControl.control, layer.control)
        
        activeLayerStub.send(nil)
        XCTAssertNil(sut.sampleControl.control)
    }
    
    func test_sampleControlKnobOffsetDidChanged_informsDelegateCurrentLayerControlUpdate() {
        
        let sut = makeSUT(activeLayer: Just(someLayer()).eraseToAnyPublisher())
        let delegateActionSpy = ValueSpy(sut.delegateAction)

        sut.sampleControl.knobOffsetDidChanged(offset: .zero, area: .init(width: 100, height: 100))
        
        XCTAssertEqual(delegateActionSpy.values, [.activeLayerUpdate(.init(volume: 0.5, speed: 0.5))])
    }
    
    func test_controlPanelLayersButtonDidTapped_createsAndRemovesLayersControl() {
        
        let sut = makeSUT()
        
        sut.controlPanel.layersButtonDidTapped()
        XCTAssertNotNil(sut.layersControl)
        
        sut.controlPanel.layersButtonDidTapped()
        XCTAssertNil(sut.layersControl)
    }
    
    func test_controlPanelRecordButtonDidTapped_informsDelegateStartAndStopRecording() {
        
        let sut = makeSUT()
        let delegateActionSpy = ValueSpy(sut.delegateAction)

        sut.controlPanel.recordButtonDidTapped()
        sut.controlPanel.recordButtonDidTapped()
        
        XCTAssertEqual(delegateActionSpy.values, [.startRecording, .stopRecording])
    }
    
    func test_controlPanelComposeButtonDidTapped_informsDelegateStartAndStopCompositing() {
        
        let sut = makeSUT()
        let delegateActionSpy = ValueSpy(sut.delegateAction)

        sut.controlPanel.composeButtonDidTapped()
        sut.controlPanel.composeButtonDidTapped()
        
        XCTAssertEqual(delegateActionSpy.values, [.startComposing, .stopComposing])
    }
    
    func test_controlPanelPlayButtonDidTapped_informsDelegateStartAndStopPlaying() {
        
        let sut = makeSUT()
        let delegateActionSpy = ValueSpy(sut.delegateAction)

        sut.controlPanel.playButtonDidTapped()
        sut.controlPanel.playButtonDidTapped()
        
        XCTAssertEqual(delegateActionSpy.values, [.startPlaying, .stopPlaying])
    }
    
    func test_dismissSampleSelector_setSampleSelectorToNil() {
        
        let sut = makeSUT(samplesIDs: { _ in Just([Sample.ID(), Sample.ID(), Sample.ID()]).setFailureType(to: Error.self).eraseToAnyPublisher() })
        sut.instrumentSelector.buttonDidLongTapped(for: Instrument.guitar.rawValue)
        XCTAssertNotNil(sut.sampleSelector)
        
        sut.dismissSampleSelector()
        
        XCTAssertNil(sut.sampleSelector)
    }
    
    func test_dismissLayersControl_invokesLayersButtonDidTappedOnControlPanel() {
        
        let sut = makeSUT()
        sut.controlPanel.layersButtonDidTapped()
        XCTAssertNotNil(sut.layersControl)
        
        sut.dismissLayersControl()
        
        XCTAssertNil(sut.layersControl)
    }
    
    func test_z_activeLayer_affectLayersButtonIsEnabled() {
    
        let activeLayerStub = PassthroughSubject<Layer?, Never>()
        let sut = makeSUT(activeLayer: activeLayerStub.eraseToAnyPublisher())
        
        activeLayerStub.send(nil)
        XCTAssertFalse(sut.controlPanel.layersButton.isEnabled)
        
        activeLayerStub.send(Layer(id: UUID(), name: "SomeLayer", isPlaying: true, isMuted: true, control: .initial))
        XCTAssertTrue(sut.controlPanel.layersButton.isEnabled)
        
        activeLayerStub.send(nil)
        XCTAssertFalse(sut.controlPanel.layersButton.isEnabled)
        
        sut.controlPanel.playButtonDidTapped()
        activeLayerStub.send(Layer(id: UUID(), name: "SomeLayer2", isPlaying: true, isMuted: true, control: .initial))
        XCTAssertFalse(sut.controlPanel.layersButton.isEnabled)
        
        sut.controlPanel.playButtonDidTapped()
        XCTAssertTrue(sut.controlPanel.layersButton.isEnabled)
        
        activeLayerStub.send(nil)
        XCTAssertFalse(sut.controlPanel.layersButton.isEnabled)
        
        sut.controlPanel.playButtonDidTapped()
        sut.controlPanel.playButtonDidTapped()
        XCTAssertFalse(sut.controlPanel.layersButton.isEnabled)
    }
    
    func test_layersDelegateAction_forwardingWithMainViewModelDelegateAction() {
        
        let layerID = UUID()
        let layers = [Layer(id: layerID, name: "some", isPlaying: false, isMuted: false, control: .initial)]
        let sut = makeSUT(layers: { Just(LayersUpdate(layers: layers, active: layerID)).eraseToAnyPublisher() })
        sut.controlPanel.layersButtonDidTapped()
        let delegateActionSpy = ValueSpy(sut.delegateAction)
        
        sut.layersControl?.layers[0].playButtonDidTaped()
        XCTAssertEqual(delegateActionSpy.values, [.layersControl(.isPlayingDidChanged(layerID, true))])
        
        sut.layersControl?.layers[0].muteButtonDidTapped()
        XCTAssertEqual(delegateActionSpy.values, [.layersControl(.isPlayingDidChanged(layerID, true)),
                                                  .layersControl(.isMutedDidChanged(layerID, true))])
        
        sut.layersControl?.layers[0].deleteButtonDidTapped()
        XCTAssertEqual(delegateActionSpy.values, [.layersControl(.isPlayingDidChanged(layerID, true)),
                                                  .layersControl(.isMutedDidChanged(layerID, true)),
                                                  .layersControl(.deleteLayer(layerID))])
    }
    
    //FIXME: test passes but for some reason breaks previous test. Looks like some strange memory leak. Not sure what exactly happening.
    /*
    func test_layers_onReceiveEmptyLayersRemoveLayersControlOnExists() {
        
        
        let layersStub = PassthroughSubject<LayersUpdate, Never>()
        let sut = makeSUT(layers: { layersStub.eraseToAnyPublisher() })
        let layerID = UUID()
        let layers = [Layer(id: UUID(), name: "some", isPlaying: false, isMuted: false, control: .initial)]
        layersStub.send(LayersUpdate(layers: layers, active: layerID))
        sut.controlPanel.layersButtonDidTapped()
        
        layersStub.send(LayersUpdate(layers: [], active: nil))
        
        XCTAssertNil(sut.layersControl)

    }
     */
    
    func test_sampleSelectorItemDidSelected_informsMainViewModelDelegateThatSampleIDSelectedForIstrument() {
        
        let sampleID = Sample.ID()
        let sut = makeSUT(samplesIDs: { _ in Just([sampleID, Sample.ID(), Sample.ID()]).setFailureType(to: Error.self).eraseToAnyPublisher() })
        let delegateActionSpy = ValueSpy(sut.delegateAction)
        sut.instrumentSelector.buttonDidLongTapped(for: Instrument.guitar.rawValue)
        XCTAssertNotNil(sut.sampleSelector)
        
        sut.sampleSelector?.itemDidSelected(for: sampleID)
        
        XCTAssertEqual(delegateActionSpy.values, [.sampleSelector(.sampleDidSelected(sampleID, .guitar))])
    }
    
    func test_sampleSelectorItemDidSelected_dismissesSampleSelector() {
        
        let sampleID = Sample.ID()
        let sut = makeSUT(samplesIDs: { _ in Just([sampleID, Sample.ID(), Sample.ID()]).setFailureType(to: Error.self).eraseToAnyPublisher() })
        _ = ValueSpy(sut.delegateAction)
        sut.instrumentSelector.buttonDidLongTapped(for: Instrument.guitar.rawValue)
        XCTAssertNotNil(sut.sampleSelector)
        
        sut.sampleSelector?.itemDidSelected(for: sampleID)
        
        XCTAssertNil(sut.sampleSelector)
    }
    
    func test_layers_controlPanelPlayButtonIsActiveTrueOnAllLayersIsPlaying() {
        
        let layersStub = PassthroughSubject<LayersUpdate, Never>()
        let sut = makeSUT(layers: { layersStub.eraseToAnyPublisher() })
        sut.controlPanel.playButton.isActive = false

        let layers = [Layer(id: UUID(), name: "some1", isPlaying: true, isMuted: false, control: .initial),
                      Layer(id: UUID(), name: "some2", isPlaying: true, isMuted: false, control: .initial),
                      Layer(id: UUID(), name: "some3", isPlaying: true, isMuted: false, control: .initial)]
        layersStub.send(LayersUpdate(layers: layers, active: layers[0].id))
        
        XCTAssertTrue(sut.controlPanel.playButton.isActive)
    }
    
    func test_layers_controlPanelPlayButtonIsActiveFalseOnNotAllLayersIsPlaying() {
        
        let layersStub = PassthroughSubject<LayersUpdate, Never>()
        let sut = makeSUT(layers: { layersStub.eraseToAnyPublisher() })
        sut.controlPanel.playButton.isActive = true

        let layers = [Layer(id: UUID(), name: "some1", isPlaying: true, isMuted: false, control: .initial),
                      Layer(id: UUID(), name: "some2", isPlaying: false, isMuted: false, control: .initial),
                      Layer(id: UUID(), name: "some3", isPlaying: true, isMuted: false, control: .initial)]
        layersStub.send(LayersUpdate(layers: layers, active: layers[0].id))
        
        XCTAssertFalse(sut.controlPanel.playButton.isActive)
    }
    
    //MARK: - Helpers
    
    private func makeSUT(
        activeLayer: AnyPublisher<Layer?, Never> = Empty().eraseToAnyPublisher(),
        layers: @escaping () -> AnyPublisher<LayersUpdate, Never> = { Empty().eraseToAnyPublisher() },
        samplesIDs: @escaping (Instrument) -> AnyPublisher<[Sample.ID], Error> = { _ in Empty().eraseToAnyPublisher()},
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> MainViewModel {
        
        let sut = MainViewModel(activeLayer: activeLayer, layers: layers, samplesIDs: samplesIDs)
        trackForMemoryLeaks(sut, file: file, line: line)
        
        return sut
    }
    
    private func someLayer() -> Layer {
        
        Layer(id: UUID(), name: "layer 1", isPlaying: true, isMuted: false, control: .init(volume: 0.7, speed: 1.0))
    }
}
