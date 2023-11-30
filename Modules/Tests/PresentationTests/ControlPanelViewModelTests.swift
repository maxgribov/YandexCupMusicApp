//
//  ControlPanelViewModelTests.swift
//  
//
//  Created by Max Gribov on 03.11.2023.
//

import XCTest
import Combine
import Presentation

final class ControlPanelViewModelTests: XCTestCase {
    
    func test_layersButtonDidTapped_informsDelegateShowLayersOnActivation() {
        
        let sut = makeSUT()
        let delegateActionSpy = ValueSpy(sut.delegateAction)
        
        sut.layersButtonDidTapped()
        
        XCTAssertEqual(delegateActionSpy.values, [.showLayers])
    }
    
    func test_layersButtonDidTapped_informsDelegateHideLayersOnDeactivation() {
        
        let sut = makeSUT()
        let delegateActionSpy = ValueSpy(sut.delegateAction)
        sut.layersButton.isActive = true
        
        sut.layersButtonDidTapped()
        
        XCTAssertEqual(delegateActionSpy.values, [.hideLayers])
    }
    
    func test_layersButtonDidTapped_makeDisabledAllOtherButtonsOnActivation() {
        
        let sut = makeSUT()
        
        sut.layersButtonDidTapped()
        
        XCTAssertEqual(sut.layersButton.isEnabled, true)
        XCTAssertEqual(sut.recordButton.isEnabled, false)
        XCTAssertEqual(sut.composeButton.isEnabled, false)
        XCTAssertEqual(sut.playButton.isEnabled, false)
    }
    
    func test_layersButtonDidTapped_makeEnableAllOtherButtonsOnDeactivation() {
        
        let sut = makeSUT()
        
        sut.layersButtonDidTapped()
        sut.layersButtonDidTapped()
        
        XCTAssertEqual(sut.layersButton.isEnabled, true)
        XCTAssertEqual(sut.recordButton.isEnabled, true)
        XCTAssertEqual(sut.composeButton.isEnabled, true)
        XCTAssertEqual(sut.playButton.isEnabled, true)
    }
    
    func test_recordButtonDidTapped_informsDelegateStartRecordingOnActivation() {
        
        let sut = makeSUT()
        let delegateActionSpy = ValueSpy(sut.delegateAction)
        
        sut.recordButtonDidTapped()
        
        XCTAssertEqual(delegateActionSpy.values, [.startRecording])
    }
    
    func test_recordButtonDidTapped_informsDelegateStopRecordingOnDeactivation() {
        
        let sut = makeSUT()
        let delegateActionSpy = ValueSpy(sut.delegateAction)
        sut.recordButton.isActive = true
        
        sut.recordButtonDidTapped()
        
        XCTAssertEqual(delegateActionSpy.values, [.stopRecording])
    }
    
    func test_recordButtonDidTapped_makeDisabledAllOtherButtonsOnActivation() {
        
        let sut = makeSUT()
        sut.layersButton.name = "active"
        
        sut.recordButtonDidTapped()
        
        XCTAssertEqual(sut.layersButton.isEnabled, false)
        XCTAssertEqual(sut.recordButton.isEnabled, true)
        XCTAssertEqual(sut.composeButton.isEnabled, false)
        XCTAssertEqual(sut.playButton.isEnabled, false)
    }
    
    func test_recordButtonDidTapped_makeEnableAllOtherButtonsOnDeactivation() {
        
        let sut = makeSUT()
        sut.layersButton.name = "active"
        
        sut.recordButtonDidTapped()
        sut.recordButtonDidTapped()
        
        XCTAssertEqual(sut.layersButton.isEnabled, true)
        XCTAssertEqual(sut.recordButton.isEnabled, true)
        XCTAssertEqual(sut.composeButton.isEnabled, true)
        XCTAssertEqual(sut.playButton.isEnabled, true)
    }
    
    func test_composeButtonDidTapped_informsDelegateToStartCompositingOnActivation() {
        
        let sut = makeSUT()
        let delegateActionSpy = ValueSpy(sut.delegateAction)
        
        sut.composeButtonDidTapped()
        
        XCTAssertEqual(delegateActionSpy.values, [.startComposing])
    }
    
    func test_composeButtonDidTapped_informsDelegateToStopCompositingOnDeactivation() {
        
        let sut = makeSUT()
        let delegateActionSpy = ValueSpy(sut.delegateAction)
        sut.composeButton.isActive = true
        
        sut.composeButtonDidTapped()
        
        XCTAssertEqual(delegateActionSpy.values, [.stopComposing])
    }
    
    func test_composeButtonDidTapped_makeDisabledAllOtherButtonsOnActivation() {
        
        let sut = makeSUT()
        sut.layersButton.name = "active"
        
        sut.composeButtonDidTapped()
        
        XCTAssertEqual(sut.layersButton.isEnabled, false)
        XCTAssertEqual(sut.recordButton.isEnabled, false)
        XCTAssertEqual(sut.composeButton.isEnabled, true)
        XCTAssertEqual(sut.playButton.isEnabled, false)
    }
    
    func test_composeButtonDidTapped_makeEnableAllOtherButtonsOnDeactivation() {
        
        let sut = makeSUT()
        sut.layersButton.name = "active"
        
        sut.composeButtonDidTapped()
        sut.composeButtonDidTapped()
        
        XCTAssertEqual(sut.layersButton.isEnabled, true)
        XCTAssertEqual(sut.recordButton.isEnabled, true)
        XCTAssertEqual(sut.composeButton.isEnabled, true)
        XCTAssertEqual(sut.playButton.isEnabled, true)
    }
    
    func test_playButtonDidTapped_informsDelegateToStartPlayingOnActivation() {
        
        let sut = makeSUT()
        let delegateActionSpy = ValueSpy(sut.delegateAction)
        
        sut.playButtonDidTapped()
        
        XCTAssertEqual(delegateActionSpy.values, [.startPlaying])
    }
    
    func test_playButtonDidTapped_informsDelegateToStopPlayingAllForIsPlayOnDeactivation() {
        
        let sut = makeSUT()
        let delegateActionSpy = ValueSpy(sut.delegateAction)
        sut.playButton.isActive = true
        
        sut.playButtonDidTapped()
        
        XCTAssertEqual(delegateActionSpy.values, [.stopPlaying])
    }
    
    func test_playButtonDidTapped_makeDisabledAllOtherButtonsButPlayButtonOnActivation() {
        
        let sut = makeSUT()
        sut.layersButton.name = "active"
        
        sut.playButtonDidTapped()
        
        XCTAssertEqual(sut.layersButton.isEnabled, true)
        XCTAssertEqual(sut.recordButton.isEnabled, false)
        XCTAssertEqual(sut.composeButton.isEnabled, false)
        XCTAssertEqual(sut.playButton.isEnabled, true)
    }
    
    func test_playButtonDidTapped_makeEnableAllOtherButtonsOnDeactivation() {
        
        let sut = makeSUT()
        sut.layersButton.name = "active"
        
        sut.playButtonDidTapped()
        sut.playButtonDidTapped()
        
        XCTAssertEqual(sut.layersButton.isEnabled, true)
        XCTAssertEqual(sut.recordButton.isEnabled, true)
        XCTAssertEqual(sut.composeButton.isEnabled, true)
        XCTAssertEqual(sut.playButton.isEnabled, true)
    }
    
    func test_composeButtonStatusUpdates_updatesPlayButtonStatus() {
        
        let composeButtonStatusUpdateStub = PassthroughSubject<Bool, Never>()
        let sut = makeSUT(composeButtonStatusUpdatesStub: composeButtonStatusUpdateStub.eraseToAnyPublisher())
        XCTAssertFalse(sut.composeButton.isActive)
        
        composeButtonStatusUpdateStub.send(true)
        XCTAssertTrue(sut.composeButton.isActive)
        
        composeButtonStatusUpdateStub.send(false)
        XCTAssertFalse(sut.composeButton.isActive)
    }
    
    func test_playButtonStatusUpdates_updatesPlayButtonStatus() {
        
        let playButtonStatusUpdateStub = PassthroughSubject<Bool, Never>()
        let sut = makeSUT(playButtonStatusUpdatesStub: playButtonStatusUpdateStub.eraseToAnyPublisher())
        XCTAssertFalse(sut.playButton.isActive)
        
        playButtonStatusUpdateStub.send(true)
        XCTAssertTrue(sut.playButton.isActive)
        
        playButtonStatusUpdateStub.send(false)
        XCTAssertFalse(sut.playButton.isActive)
    }
    
    //MARK: - Helpers
    
    private func makeSUT(
        layersButton: LayersButtonViewModel = LayersButtonViewModel(name: ControlPanelViewModel.layersButtonDefaultName, isActive: false, isEnabled: true),
        recordButton: ToggleButtonViewModel = ToggleButtonViewModel(type: .record, isActive: false, isEnabled: true),
        composeButton: ToggleButtonViewModel = ToggleButtonViewModel(type: .compose, isActive: false, isEnabled: true),
        playButton: ToggleButtonViewModel = ToggleButtonViewModel(type: .play, isActive: false, isEnabled: true),
        layerButtonNameUpdatesStub: AnyPublisher<String?, Never> = Empty().eraseToAnyPublisher(),
        composeButtonStatusUpdatesStub: AnyPublisher<Bool, Never> = Empty().eraseToAnyPublisher(),
        playButtonStatusUpdatesStub: AnyPublisher<Bool, Never> = Empty().eraseToAnyPublisher(),
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> ControlPanelViewModel {
        
        let sut = ControlPanelViewModel(
            layersButton: layersButton,
            recordButton: recordButton,
            composeButton: composeButton,
            playButton: playButton,
            layersButtonNameUpdates: layerButtonNameUpdatesStub,
            composeButtonStatusUpdates: composeButtonStatusUpdatesStub,
            playButtonStatusUpdates: playButtonStatusUpdatesStub
        )
        
        trackForMemoryLeaks(sut, file: file, line: line)
        
        return sut
        
    }
}
