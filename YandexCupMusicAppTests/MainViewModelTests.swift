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
        
        let (sut, _, _, _, _, _, _) = makeSUT()
        
        XCTAssertEqual(sut.instrumentSelector.buttons.map(\.instrument), [.guitar, .drums, .brass])
    }
    
    func test_init_sampleControlWithControlNil() {
        
        let (sut, _, _, _, _, _, _) = makeSUT()
        
        XCTAssertNil(sut.sampleControl.control)
    }
    
    func test_init_controlPanelContainsCorrectButtons() {

        let (sut, _, _, _, _, _, _) = makeSUT()
        
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
        
        let (sut, _, _, _, _, _, _) = makeSUT()
        
        XCTAssertNil(sut.sampleSelector)
    }
    
    func test_instrumentSelectorButtonDidTapped_informDlegateThatDefaultSampleSelected() {
        
        let (sut, _, _, _, _, _, _) = makeSUT()
        let delegateActionSpy = ValueSpy(sut.delegateAction)
        
        sut.instrumentSelector.buttonDidTapped(for: Instrument.brass.rawValue)
        
        XCTAssertEqual(delegateActionSpy.values, [.defaultSampleSelected(.brass)])
    }
    
    func test_instrumentSelectorButtonDidLongTapped_createsSampleSelectorViewModel() {
        
        let (sut, _, _, _, _, _, _) = makeSUT()
        
        sut.instrumentSelector.buttonDidLongTapped(for: Instrument.guitar.rawValue)
        
        XCTAssertEqual(sut.sampleSelector?.instrument, .guitar)
    }
    
    func test_activeLevel_setsAndRemovesControlValueForSampleControl() {
        
        let (sut, activeLayerStub, _, _, _, _, _) = makeSUT()
        
        XCTAssertNil(sut.sampleControl.control)
        
        let layer = someLayer()
        activeLayerStub.publishUpdate(someLayer())
        XCTAssertEqual(sut.sampleControl.control, layer.control)
        
        activeLayerStub.publishUpdate(nil)
        XCTAssertNil(sut.sampleControl.control)
    }
    
    func test_sampleControlKnobOffsetDidChanged_informsDelegateCurrentLayerControlUpdate() {
        
        let (sut, activeLayerStub, _, _, _, _, _) = makeSUT()
        let delegateActionSpy = ValueSpy(sut.delegateAction)
        activeLayerStub.publishUpdate(someLayer())

        sut.sampleControl.knobOffsetDidChanged(offset: .zero, area: .init(width: 100, height: 100))
        
        XCTAssertEqual(delegateActionSpy.values, [.activeLayerUpdate(.init(volume: 0.5, speed: 0.5))])
    }
    
    func test_controlPanelLayersButtonDidTapped_createsAndRemovesLayersControl() {
        
        let (sut, _, layersUpdate, _, _, _, _) = makeSUT()
        let layers = [someLayer(), someLayer()]
        layersUpdate.publish(.init(layers: layers, active: layers[0].id))
        
        sut.controlPanel.layersButtonDidTapped()
        XCTAssertNotNil(sut.layersControl)
        
        sut.controlPanel.layersButtonDidTapped()
        XCTAssertNil(sut.layersControl)
    }
    
    func test_controlPanelRecordButtonDidTapped_informsDelegateStartAndStopRecording() {
        
        let (sut, _, _, _, _, _, _) = makeSUT()
        let delegateActionSpy = ValueSpy(sut.delegateAction)

        sut.controlPanel.recordButtonDidTapped()
        sut.controlPanel.recordButtonDidTapped()
        
        XCTAssertEqual(delegateActionSpy.values, [.startRecording, .stopRecording])
    }
    
    func test_controlPanelComposeButtonDidTapped_informsDelegateStartAndStopCompositing() {
        
        let (sut, _, _, _, _, _, _) = makeSUT()
        let delegateActionSpy = ValueSpy(sut.delegateAction)

        sut.controlPanel.composeButtonDidTapped()
        sut.controlPanel.composeButtonDidTapped()
        
        XCTAssertEqual(delegateActionSpy.values, [.startComposing, .stopComposing])
    }
    
    func test_controlPanelPlayButtonDidTapped_informsDelegateStartAndStopPlaying() {
        
        let (sut, _, _, _, _, _, _) = makeSUT()
        let delegateActionSpy = ValueSpy(sut.delegateAction)

        sut.controlPanel.playButtonDidTapped()
        sut.controlPanel.playButtonDidTapped()
        
        XCTAssertEqual(delegateActionSpy.values, [.startPlaying, .stopPlaying])
    }
    
    func test_dismissSampleSelector_setSampleSelectorToNil() {
        
        let (sut, _, _, _, _, _, _) = makeSUT()
        sut.instrumentSelector.buttonDidLongTapped(for: Instrument.guitar.rawValue)
        XCTAssertNotNil(sut.sampleSelector)
        
        sut.dismissSampleSelector()
        
        XCTAssertNil(sut.sampleSelector)
    }
    
    func test_dismissLayersControl_invokesLayersButtonDidTappedOnControlPanel() {
        
        let (sut, _, layersUpdate, _, _, _, _) = makeSUT()
        
        let layers = [someLayer(), someLayer()]
        layersUpdate.publish(.init(layers: layers, active: layers[0].id))
        sut.controlPanel.layersButtonDidTapped()
        XCTAssertNotNil(sut.layersControl)
        
        sut.dismissLayersControl()
        
        XCTAssertNil(sut.layersControl)
    }
    
    func test_activeLayer_affectLayersButtonIsEnabled() {
    
        let (sut, activeLayerStub, _, _, _, _, _) = makeSUT()
        
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

        let (sut, _, layersUpdate, _, _, _, _) = makeSUT()
        
        let layerID = UUID()
        let layers = [someLayer(id: layerID)]
        layersUpdate.publish(.init(layers: layers, active: layerID))
        sut.controlPanel.layersButtonDidTapped()
        let delegateActionSpy = ValueSpy(sut.delegateAction)
        
        sut.layersControl?.playButtonDidTaped(for: layerID)
        XCTAssertEqual(delegateActionSpy.values, [.layersControl(.isPlayingDidChanged(layerID, true))])
        
        sut.layersControl?.muteButtonDidTapped(for: layerID)
        XCTAssertEqual(delegateActionSpy.values, [.layersControl(.isPlayingDidChanged(layerID, true)),
                                                  .layersControl(.isMutedDidChanged(layerID, true))])
        
        sut.layersControl?.deleteButtonDidTapped(for: layerID)
        XCTAssertEqual(delegateActionSpy.values, [.layersControl(.isPlayingDidChanged(layerID, true)),
                                                  .layersControl(.isMutedDidChanged(layerID, true)),
                                                  .layersControl(.deleteLayer(layerID))])
    }
    
    func test_layers_onReceiveEmptyLayersRemoveLayersControlOnExists() {
        
        let (sut, _, layersStub, _, _, _, _) = makeSUT()
        let layerID = UUID()
        let layers = [someLayer()]
        layersStub.publish(LayersUpdate(layers: layers, active: layerID))
        sut.controlPanel.layersButtonDidTapped()
        
        layersStub.publish(LayersUpdate(layers: [], active: nil))
        
        XCTAssertNil(sut.layersControl)
    }
    
    func test_sampleSelectorItemDidSelected_informsMainViewModelDelegateThatSampleIDSelectedForIstrument() {

        let (sut, _, _, samplesIdsStub, _, _, _) = makeSUT()
        let sampleID = samplesIdsStub.stubbed[0]
        let delegateActionSpy = ValueSpy(sut.delegateAction)
        sut.instrumentSelector.buttonDidLongTapped(for: Instrument.guitar.rawValue)
        XCTAssertNotNil(sut.sampleSelector)
        
        sut.sampleSelector?.itemDidSelected(for: sampleID)
        
        XCTAssertEqual(delegateActionSpy.values, [.sampleSelector(.sampleDidSelected(sampleID, .guitar))])
    }
    
    func test_sampleSelectorItemDidSelected_dismissesSampleSelector() {
        
        let (sut, _, _, samplesIdsStub, _, _, _) = makeSUT()
        let sampleID = samplesIdsStub.stubbed[0]
        // delegateActionSubject is subscriber to sampleSelector.delegateAction. Active subscription to it required for that all pipeline works.
        _ = sut.delegateAction.sink { _ in }
        sut.instrumentSelector.buttonDidLongTapped(for: Instrument.guitar.rawValue)
        XCTAssertNotNil(sut.sampleSelector)
        
        sut.sampleSelector?.itemDidSelected(for: sampleID)
        
        XCTAssertNil(sut.sampleSelector)
    }
    
    func test_layers_controlPanelPlayButtonIsActiveTrueOnAllLayersIsPlaying() {
        
        let (sut, _, layersStub, _, _, _, _) = makeSUT()
        sut.controlPanel.playButton.isActive = false

        let layers = [someLayer(name: "one", isPlaying: true),
                      someLayer(name: "two", isPlaying: true),
                      someLayer(name: "three", isPlaying: true)]
        layersStub.publish(LayersUpdate(layers: layers, active: layers[0].id))
        
        XCTAssertTrue(sut.controlPanel.playButton.isActive)
    }
    
    func test_layers_controlPanelPlayButtonIsActiveFalseOnNotAllLayersIsPlaying() {
        
        let (sut, _, layersStub, _, _, _, _) = makeSUT()
        sut.controlPanel.playButton.isActive = true

        let layers = [someLayer(name: "one", isPlaying: true),
                      someLayer(name: "two", isPlaying: false),
                      someLayer(name: "three", isPlaying: true)]
        layersStub.publish(LayersUpdate(layers: layers, active: layers[0].id))
        
        XCTAssertFalse(sut.controlPanel.playButton.isActive)
    }
    
    func test_playingProgressUpdates_updatePlayingProgressProperty() {
        
        let (sut, _, _, _, playingProgressUpdatesStub, _, _) = makeSUT()
        
        XCTAssertEqual(sut.playingProgress, 0, accuracy: .ulpOfOne)
        
        playingProgressUpdatesStub.publish(0.5)
        XCTAssertEqual(sut.playingProgress, 0.5, accuracy: .ulpOfOne)
    }
    
    func test_isCompositing_updatesCompositingButtonIsActiveState() {
        
        let (sut, _, _, _, _, compositingStub, _) = makeSUT()
        XCTAssertFalse(sut.controlPanel.composeButton.isActive)
        
        compositingStub.publish(true)
        XCTAssertTrue(sut.controlPanel.composeButton.isActive)
        
        compositingStub.publish(false)
        XCTAssertFalse(sut.controlPanel.composeButton.isActive)
    }
    
    func test_compositingReady_updatesSheetState() {
        
        let (sut, _, _, _, _, _, sheetUpdate) = makeSUT()
        XCTAssertNil(sut.sheet)
        
        let url = URL(string: "http://any-url.com")!
        sheetUpdate.publish(.activity(url))
        XCTAssertEqual(sut.sheet, .activity(url))
        
        sheetUpdate.publish(nil)
        XCTAssertNil(sut.sheet)
    }
    
    //MARK: - Helpers
    
    private func makeSUT(
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> (
        sut: MainViewModel,
        activeLayerUpdates: ActiveLayerUpdatesSub,
        layersUpdate: LayersUpdateStub,
        sampleIds: SamplesIDsStub,
        playingProgressUpdates: PlayingProgressUpdatesStub,
        isCompositing: CompositingStub,
        compositingReady: SheetUpdateStub
    ) {
        
        let activeLayerUpdatedStub = ActiveLayerUpdatesSub()
        let layersUpdateStub = LayersUpdateStub()
        let samplesIDsStub = SamplesIDsStub()
        let playingProgressUpdatesStub = PlayingProgressUpdatesStub()
        let compositingStub = CompositingStub()
        let sheetUpdateStub = SheetUpdateStub()
        let sut = MainViewModel(
            instrumentSelector: .initial,
            sampleControl: .init(initial: nil, update: activeLayerUpdatedStub.updates.control()),
            controlPanel: .init(
                layersButton: .init(
                    name: .layersButtonDefaultName, isActive: false, isEnabled: true),
                    recordButton: .init(type: .record, isActive: false, isEnabled: true),
                    composeButton: .init(type: .compose, isActive: false, isEnabled: true),
                    playButton: .init(type: .play, isActive: false, isEnabled: true),
                layersButtonNameUpdates: activeLayerUpdatedStub.updates.map { $0?.name }.eraseToAnyPublisher(),
                composeButtonStatusUpdates: compositingStub.updates,
                playButtonStatusUpdates: layersUpdateStub.update().isPlayingAll()),
            playingProgress: 0,
            makeSampleSelector: { instrument in samplesIDsStub.sampleIdsFor(instrument).makeSampleItemViewModels().map { SampleSelectorViewModel(instrument: instrument, items: $0)}.eraseToAnyPublisher() },
            makeLayersControl: { LayersControlViewModel(initial: layersUpdateStub.current.makeLayerViewModels(), updates: layersUpdateStub.update().makeLayerViewModels())},
            playingProgressUpdates: playingProgressUpdatesStub.updates,
            sheetUpdates: sheetUpdateStub.updates
        )
        
        trackForMemoryLeaks(sut, file: file, line: line)
        trackForMemoryLeaks(activeLayerUpdatedStub, file: file, line: line)
        trackForMemoryLeaks(layersUpdateStub, file: file, line: line)
        trackForMemoryLeaks(samplesIDsStub, file: file, line: line)
        trackForMemoryLeaks(playingProgressUpdatesStub, file: file, line: line)
        trackForMemoryLeaks(compositingStub, file: file, line: line)
        trackForMemoryLeaks(sheetUpdateStub, file: file, line: line)
        
        return (sut, activeLayerUpdatedStub, layersUpdateStub, samplesIDsStub, playingProgressUpdatesStub, compositingStub, sheetUpdateStub)
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
    
    private class LayersUpdateStub {
        
        private let updateSubject = CurrentValueSubject<LayersUpdate, Never>.init(.init(layers: [], active: nil))
        
        var current: LayersUpdate {
            updateSubject.value
        }
        
        func update() -> AnyPublisher<LayersUpdate, Never> {
            
            updateSubject.eraseToAnyPublisher()
        }
        
        func publish(_ update: LayersUpdate) {
            
            updateSubject.send(update)
        }
    }
    
    private class SamplesIDsStub {
        
        let stubbed: [Sample.ID] = [Sample.ID(), Sample.ID(), Sample.ID()]
        
        func sampleIdsFor(_ instrument: Instrument) -> AnyPublisher<[Sample.ID], Error> {
            
            Just(stubbed).setFailureType(to: Error.self).eraseToAnyPublisher()
        }
    }
    
    private class PlayingProgressUpdatesStub {
        
        private let updatesSubject = PassthroughSubject<Double, Never>()
        
        var updates: AnyPublisher<Double, Never> {
            
            updatesSubject.eraseToAnyPublisher()
        }
        
        func publish(_ value: Double) {
            
            updatesSubject.send(value)
        }
    }
    
    private class CompositingStub {
        
        private let updatesSubject = PassthroughSubject<Bool, Never>()
        
        var updates: AnyPublisher<Bool, Never> {
            
            updatesSubject.eraseToAnyPublisher()
        }
        
        func publish(_ value: Bool) {
            
            updatesSubject.send(value)
        }
    }
    
    private class SheetUpdateStub {
        
        private let updatesSubject = PassthroughSubject<MainViewModel.Sheet?, Never>()
        
        var updates: AnyPublisher<MainViewModel.Sheet?, Never> {
            
            updatesSubject.eraseToAnyPublisher()
        }
        
        func publish(_ value: MainViewModel.Sheet?) {
            
            updatesSubject.send(value)
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

extension LayersUpdate {
    
    func makeLayerViewModels() -> [LayerViewModel] {
        
        layers.map { layer in
            
            LayerViewModel(
                id: layer.id,
                name: layer.name,
                isPlaying: layer.isPlaying,
                isMuted: layer.isMuted,
                isActive: layer.id == active
            )
        }
    }
}
