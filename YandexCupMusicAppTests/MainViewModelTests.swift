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
        
        let (sut, _) = makeSUT()
        
        XCTAssertEqual(sut.instrumentSelector.buttons.map(\.instrument), [.guitar, .drums, .brass])
    }
    
    func test_init_sampleControlWithControlNil() {
        
        let (sut, _) = makeSUT()
        
        XCTAssertNil(sut.sampleControl.control)
    }
    
    func test_init_controlPanelContainsCorrectButtons() {

        let (sut, _) = makeSUT()
        
        XCTAssertEqual(sut.controlPanel.layersButton.name, "Слои")
        XCTAssertEqual(sut.controlPanel.layersButton.isActive, false)
        XCTAssertEqual(sut.controlPanel.layersButton.isEnabled, true)
        
        XCTAssertEqual(sut.controlPanel.recordButton.type, .record)
        XCTAssertEqual(sut.controlPanel.layersButton.isActive, false)
        XCTAssertEqual(sut.controlPanel.layersButton.isEnabled, true)
        
        XCTAssertEqual(sut.controlPanel.composeButton.type, .compose)
        XCTAssertEqual(sut.controlPanel.layersButton.isActive, false)
        XCTAssertEqual(sut.controlPanel.layersButton.isEnabled, true)
        
        XCTAssertEqual(sut.controlPanel.playButton.type, .play)
        XCTAssertEqual(sut.controlPanel.layersButton.isActive, false)
        XCTAssertEqual(sut.controlPanel.layersButton.isEnabled, true)
    }
    
    func test_init_sampleSelectorNil() {
        
        let (sut, _) = makeSUT()
        
        XCTAssertNil(sut.sampleSelector)
    }
    
    func test_instrumentSelectorButtonDidTapped_informDlegateThatDefaultSampleSelected() {
        
        let (sut, _) = makeSUT()
        let delegateActionSpy = ValueSpy(sut.delegateAction)
        
        sut.instrumentSelector.buttonDidTapped(for: Instrument.brass.rawValue)
        
        XCTAssertEqual(delegateActionSpy.values, [.defaultSampleSelected(.brass)])
    }
    
    func test_instrumentSelectorButtonDidLongTapped_createsSampleSelectorViewModel() {
        
        let (sut, _) = makeSUT(samplesIDs: { _ in Just([Sample.ID(), Sample.ID(), Sample.ID()]).setFailureType(to: Error.self).eraseToAnyPublisher() })
        
        sut.instrumentSelector.buttonDidLongTapped(for: Instrument.guitar.rawValue)
        
        XCTAssertEqual(sut.sampleSelector?.instrument, .guitar)
    }
    
    func test_activeLevel_setsAndRemovesControlValueForSampleControl() {
        
        let (sut, activeLayerStub) = makeSUT()
        
        XCTAssertNil(sut.sampleControl.control)
        
        let layer = someLayer()
        activeLayerStub.publishUpdate(someLayer())
        XCTAssertEqual(sut.sampleControl.control, layer.control)
        
        activeLayerStub.publishUpdate(nil)
        XCTAssertNil(sut.sampleControl.control)
    }
    
    func test_sampleControlKnobOffsetDidChanged_informsDelegateCurrentLayerControlUpdate() {
        
        let (sut, activeLayerStub) = makeSUT()
        let delegateActionSpy = ValueSpy(sut.delegateAction)
        activeLayerStub.publishUpdate(someLayer())

        sut.sampleControl.knobOffsetDidChanged(offset: .zero, area: .init(width: 100, height: 100))
        
        XCTAssertEqual(delegateActionSpy.values, [.activeLayerUpdate(.init(volume: 0.5, speed: 0.5))])
    }
    
    func test_controlPanelLayersButtonDidTapped_createsAndRemovesLayersControl() {
        
        let (sut, _) = makeSUT()
        
        sut.controlPanel.layersButtonDidTapped()
        XCTAssertNotNil(sut.layersControl)
        
        sut.controlPanel.layersButtonDidTapped()
        XCTAssertNil(sut.layersControl)
    }
    
    func test_controlPanelRecordButtonDidTapped_informsDelegateStartAndStopRecording() {
        
        let (sut, _) = makeSUT()
        let delegateActionSpy = ValueSpy(sut.delegateAction)

        sut.controlPanel.recordButtonDidTapped()
        sut.controlPanel.recordButtonDidTapped()
        
        XCTAssertEqual(delegateActionSpy.values, [.startRecording, .stopRecording])
    }
    
    func test_controlPanelComposeButtonDidTapped_informsDelegateStartAndStopCompositing() {
        
        let (sut, _) = makeSUT()
        let delegateActionSpy = ValueSpy(sut.delegateAction)

        sut.controlPanel.composeButtonDidTapped()
        sut.controlPanel.composeButtonDidTapped()
        
        XCTAssertEqual(delegateActionSpy.values, [.startComposing, .stopComposing])
    }
    
    func test_controlPanelPlayButtonDidTapped_informsDelegateStartAndStopPlaying() {
        
        let (sut, _) = makeSUT()
        let delegateActionSpy = ValueSpy(sut.delegateAction)

        sut.controlPanel.playButtonDidTapped()
        sut.controlPanel.playButtonDidTapped()
        
        XCTAssertEqual(delegateActionSpy.values, [.startPlaying, .stopPlaying])
    }
    
    func test_dismissSampleSelector_setSampleSelectorToNil() {
        
        let (sut, _) = makeSUT(samplesIDs: { _ in Just([Sample.ID(), Sample.ID(), Sample.ID()]).setFailureType(to: Error.self).eraseToAnyPublisher() })
        sut.instrumentSelector.buttonDidLongTapped(for: Instrument.guitar.rawValue)
        XCTAssertNotNil(sut.sampleSelector)
        
        sut.dismissSampleSelector()
        
        XCTAssertNil(sut.sampleSelector)
    }
    
    func test_dismissLayersControl_invokesLayersButtonDidTappedOnControlPanel() {
        
        let (sut, _) = makeSUT()
        sut.controlPanel.layersButtonDidTapped()
        XCTAssertNotNil(sut.layersControl)
        
        sut.dismissLayersControl()
        
        XCTAssertNil(sut.layersControl)
    }
    
    func test_activeLayer_affectLayersButtonIsEnabled() {
    
        let (sut, activeLayerStub) = makeSUT()
        
        activeLayerStub.publishUpdate(nil)
        XCTAssertFalse(sut.controlPanel.layersButton.isEnabled)
        
        activeLayerStub.publishUpdate(someLayer())
        XCTAssertTrue(sut.controlPanel.layersButton.isEnabled)
        
        activeLayerStub.publishUpdate(nil)
        XCTAssertFalse(sut.controlPanel.layersButton.isEnabled)
        
        sut.controlPanel.playButtonDidTapped()
        activeLayerStub.publishUpdate(someLayer(name: "some other layer"))
        XCTAssertFalse(sut.controlPanel.layersButton.isEnabled)
        
        sut.controlPanel.playButtonDidTapped()
        XCTAssertFalse(sut.controlPanel.layersButton.isEnabled)
        
        activeLayerStub.publishUpdate(nil)
        XCTAssertFalse(sut.controlPanel.layersButton.isEnabled)
        
        sut.controlPanel.playButtonDidTapped()
        sut.controlPanel.playButtonDidTapped()
        XCTAssertFalse(sut.controlPanel.layersButton.isEnabled)
    }
    
    func test_layersDelegateAction_forwardingWithMainViewModelDelegateAction() {
        
        let layerID = UUID()
        let layers = [someLayer(id: layerID)]
        let (sut, _) = makeSUT(layers: { Just(LayersUpdate(layers: layers, active: layerID)).eraseToAnyPublisher() })
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
    
    func test_layers_onReceiveEmptyLayersRemoveLayersControlOnExists() {
        
        let layersStub = PassthroughSubject<LayersUpdate, Never>()
        let (sut, _) = makeSUT(layers: { layersStub.eraseToAnyPublisher() })
        let layerID = UUID()
        let layers = [someLayer()]
        layersStub.send(LayersUpdate(layers: layers, active: layerID))
        sut.controlPanel.layersButtonDidTapped()
        
        layersStub.send(LayersUpdate(layers: [], active: nil))
        
        XCTAssertNil(sut.layersControl)
    }
    
    func test_sampleSelectorItemDidSelected_informsMainViewModelDelegateThatSampleIDSelectedForIstrument() {
        
        let sampleID = Sample.ID()
        let (sut, _) = makeSUT(samplesIDs: { _ in Just([sampleID, Sample.ID(), Sample.ID()]).setFailureType(to: Error.self).eraseToAnyPublisher() })
        let delegateActionSpy = ValueSpy(sut.delegateAction)
        sut.instrumentSelector.buttonDidLongTapped(for: Instrument.guitar.rawValue)
        XCTAssertNotNil(sut.sampleSelector)
        
        sut.sampleSelector?.itemDidSelected(for: sampleID)
        
        XCTAssertEqual(delegateActionSpy.values, [.sampleSelector(.sampleDidSelected(sampleID, .guitar))])
    }
    
    func test_sampleSelectorItemDidSelected_dismissesSampleSelector() {
        
        let sampleID = Sample.ID()
        let (sut, _) = makeSUT(samplesIDs: { _ in Just([sampleID, Sample.ID(), Sample.ID()]).setFailureType(to: Error.self).eraseToAnyPublisher() })
        // delegateActionSubject is subscriber to sampleSelector.delegateAction. Active subscription to it required for that all pipeline works.
        _ = sut.delegateAction.sink { _ in }
        sut.instrumentSelector.buttonDidLongTapped(for: Instrument.guitar.rawValue)
        XCTAssertNotNil(sut.sampleSelector)
        
        sut.sampleSelector?.itemDidSelected(for: sampleID)
        
        XCTAssertNil(sut.sampleSelector)
    }
    
    func test_layers_controlPanelPlayButtonIsActiveTrueOnAllLayersIsPlaying() {
        
        let layersStub = PassthroughSubject<LayersUpdate, Never>()
        let (sut, _) = makeSUT(layers: { layersStub.eraseToAnyPublisher() })
        sut.controlPanel.playButton.isActive = false

        let layers = [someLayer(name: "one", isPlaying: true),
                      someLayer(name: "two", isPlaying: true),
                      someLayer(name: "three", isPlaying: true)]
        layersStub.send(LayersUpdate(layers: layers, active: layers[0].id))
        
        XCTAssertTrue(sut.controlPanel.playButton.isActive)
    }
    
    func test_layers_controlPanelPlayButtonIsActiveFalseOnNotAllLayersIsPlaying() {
        
        let layersStub = PassthroughSubject<LayersUpdate, Never>()
        let (sut, _) = makeSUT(layers: { layersStub.eraseToAnyPublisher() })
        sut.controlPanel.playButton.isActive = true

        let layers = [someLayer(name: "one", isPlaying: true),
                      someLayer(name: "two", isPlaying: false),
                      someLayer(name: "three", isPlaying: true)]
        layersStub.send(LayersUpdate(layers: layers, active: layers[0].id))
        
        XCTAssertFalse(sut.controlPanel.playButton.isActive)
    }
    
    func test_playingProgressUpdates_updatePlayingProgressProperty() {
        
        let playingProgressUpdatesStub = PassthroughSubject<Double, Never>()
        let (sut, _) = makeSUT(playingProgressUpdates: playingProgressUpdatesStub.eraseToAnyPublisher())
        
        XCTAssertEqual(sut.playingProgress, 0, accuracy: .ulpOfOne)
        
        playingProgressUpdatesStub.send(0.5)
        XCTAssertEqual(sut.playingProgress, 0.5, accuracy: .ulpOfOne)
    }
    
    //MARK: - Helpers
    
    private func makeSUT(
        layers: @escaping () -> AnyPublisher<LayersUpdate, Never> = { Empty().eraseToAnyPublisher() },
        samplesIDs: @escaping (Instrument) -> AnyPublisher<[Sample.ID], Error> = { _ in Empty().eraseToAnyPublisher()},
        playingProgressUpdates: AnyPublisher<Double, Never> = Empty().eraseToAnyPublisher(),
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> (sut: MainViewModel, activeLayerUpdates: ActiveLayerUpdatesSub) {
        
        let activeLayerUpdatedStub = ActiveLayerUpdatesSub()
        let sut = MainViewModel(activeLayerUpdates: activeLayerUpdatedStub.updates, layersUpdated: layers, samplesIDs: samplesIDs, playingProgressUpdates: playingProgressUpdates)
        
        trackForMemoryLeaks(sut, file: file, line: line)
        trackForMemoryLeaks(activeLayerUpdatedStub, file: file, line: line)
        
        return (sut, activeLayerUpdatedStub)
    }
    
    private class ActiveLayerUpdatesSub {
        
        private let updatesSubject = PassthroughSubject<Layer?, Never>()
        
        var updates: AnyPublisher<Layer?, Never> {
            updatesSubject.eraseToAnyPublisher()
        }
        
        func publishUpdate(_ layer: Layer?) {
            
            updatesSubject.send(layer)
        }
    }
    
    private func someLayer(
        id: Layer.ID = Layer.ID(),
        name: String = "Some Layer",
        isPlaying: Bool = false,
        isMuted: Bool = false,
        control: Layer.Control = .initial
    ) -> Layer {
        
        Layer(
            id: id,
            name: name,
            isPlaying: isPlaying,
            isMuted: isMuted,
            control: control
        )
    }
}
