//
//  ControlPanelViewModelTests.swift
//  
//
//  Created by Max Gribov on 03.11.2023.
//

import XCTest
import Combine

final class ControlPanelViewModel {
    
    let layersButton: LayersButtonViewModel
    let recordButton: ToggleButtonViewModel
    let composeButton: ToggleButtonViewModel
    let playButton: ToggleButtonViewModel
    
    private let delegateActionSubject = PassthroughSubject<DelegateAction, Never>()
    
    init(
        layersButton: LayersButtonViewModel,
        recordButton: ToggleButtonViewModel,
        composeButton: ToggleButtonViewModel,
        playButton: ToggleButtonViewModel
    ) {
        self.layersButton = layersButton
        self.recordButton = recordButton
        self.composeButton = composeButton
        self.playButton = playButton
    }
    
    var delegateAction: AnyPublisher<DelegateAction, Never> {
        
        delegateActionSubject.eraseToAnyPublisher()
    }
    
    func layersButtonDidTapped() {
        
        layersButton.isActive.toggle()
        delegateActionSubject.send(layersButton.isActive ? .showLayers : .hideLayers)
        set(all: [recordButton, composeButton, playButton], to: !layersButton.isActive)
    }
    
    func recordButtonDidTapped() {
        
        recordButton.isActive.toggle()
        delegateActionSubject.send(recordButton.isActive ? .startRecording : .stopRecording)
    }
    
    func composeButtonDidTapped() {
        
        composeButton.isActive.toggle()
        delegateActionSubject.send(composeButton.isActive ? .startComposing : .stopComposing)
    }
    
    func playButtonDidTapped() {
        
        playButton.isActive.toggle()
        delegateActionSubject.send(playButton.isActive ? .startPlaying : .stopPlaying)
    }
    
    private func set(all items: [Enablable], to isEnabled: Bool) {
        
        for var item in items {
            
            item.isEnabled = isEnabled
        }
    }
}

extension ControlPanelViewModel {
    
    enum DelegateAction: Equatable {
        
        case showLayers
        case hideLayers
        case startRecording
        case stopRecording
        case startComposing
        case stopComposing
        case startPlaying
        case stopPlaying
    }
    
    static let initial = ControlPanelViewModel(layersButton: .initial, recordButton: .initialRecord, composeButton: .initialCompose, playButton: .initialPlay)
}

protocol Enablable {
    
    var isEnabled: Bool { get set }
}

final class LayersButtonViewModel: ObservableObject {
    
    @Published var name: String
    @Published var isActive: Bool
    @Published var isEnabled: Bool
    
    init(name: String, isActive: Bool, isEnabled: Bool) {
        
        self.name = name
        self.isActive = isActive
        self.isEnabled = isEnabled
    }
}

extension LayersButtonViewModel {
    
    static let initial = LayersButtonViewModel(name: "Слои", isActive: false, isEnabled: true)
}

final class ToggleButtonViewModel: ObservableObject, Enablable {
    
    let type: Kind
    @Published var isActive: Bool
    @Published var isEnabled: Bool
    
    init(type: Kind, isActive: Bool, isEnabled: Bool) {
        
        self.type = type
        self.isActive = isActive
        self.isEnabled = isEnabled
    }
    
    enum Kind {
        
        case record
        case compose
        case play
    }
}

extension ToggleButtonViewModel {
    
    static let initialRecord = ToggleButtonViewModel(type: .record, isActive: false, isEnabled: true)
    static let initialCompose = ToggleButtonViewModel(type: .compose, isActive: false, isEnabled: true)
    static let initialPlay = ToggleButtonViewModel(type: .play, isActive: false, isEnabled: true)
}

final class ControlPanelViewModelTests: XCTestCase {
    
    func test_layersButtonDidTapped_informsDelegateShowLayersOnActivation() {
        
        let sut = makeSUT()
        let delegateActionSpy = ValueSpy(sut.delegateAction)
        sut.layersButton.isActive = false
        
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
        sut.layersButton.isActive = false
        
        sut.layersButtonDidTapped()
        
        XCTAssertEqual(sut.layersButton.isEnabled, true)
        XCTAssertEqual(sut.recordButton.isEnabled, false)
        XCTAssertEqual(sut.composeButton.isEnabled, false)
        XCTAssertEqual(sut.playButton.isEnabled, false)
    }
    
    func test_layersButtonDidTapped_makeEnableAllOtherButtonsOnDeactivation() {
        
        let sut = makeSUT()
        sut.layersButton.isActive = true
        
        sut.layersButtonDidTapped()
        
        XCTAssertEqual(sut.layersButton.isEnabled, true)
        XCTAssertEqual(sut.recordButton.isEnabled, true)
        XCTAssertEqual(sut.composeButton.isEnabled, true)
        XCTAssertEqual(sut.playButton.isEnabled, true)
    }
    
    func test_recordButtonDidTapped_informsDelegateStartRecordingOnActivation() {
        
        let sut = makeSUT()
        let delegateActionSpy = ValueSpy(sut.delegateAction)
        sut.recordButton.isActive = false
        
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
    
    func test_composeButtonDidTapped_informsDelegateToStartCompositingOnActivation() {
        
        let sut = makeSUT()
        let delegateActionSpy = ValueSpy(sut.delegateAction)
        sut.composeButton.isActive = false
        
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
    
    func test_playAllButtonDidTapped_informsDelegateToStartPlayingOnActivation() {
        
        let sut = makeSUT()
        let delegateActionSpy = ValueSpy(sut.delegateAction)
        sut.playButton.isActive = false
        
        sut.playButtonDidTapped()
        
        XCTAssertEqual(delegateActionSpy.values, [.startPlaying])
    }
    
    func test_playAllButtonDidTapped_informsDelegateToStopPlayingAllForIsPlayOnDeactivation() {
        
        let sut = makeSUT()
        let delegateActionSpy = ValueSpy(sut.delegateAction)
        sut.playButton.isActive = true
        
        sut.playButtonDidTapped()
        
        XCTAssertEqual(delegateActionSpy.values, [.stopPlaying])
    }
    
    //MARK: - Helpers
    
    private func makeSUT(
        layersButton: LayersButtonViewModel = .initial,
        recordButton: ToggleButtonViewModel = .initialRecord,
        composeButton: ToggleButtonViewModel = .initialCompose,
        playButton: ToggleButtonViewModel = .initialPlay,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> ControlPanelViewModel {
        
        let sut = ControlPanelViewModel(
            layersButton: layersButton,
            recordButton: recordButton,
            composeButton: composeButton,
            playButton: playButton
        )
        
        trackForMemoryLeaks(sut, file: file, line: line)
        
        return sut
        
    }
}
