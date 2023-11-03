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
    @Published var isRecordButtonActive: Bool
    @Published var isComposeButtonActive: Bool
    @Published var isPlayButtonActive: Bool
    
    private let delegateActionSubject = PassthroughSubject<DelegateAction, Never>()
    
    init(layersButton: LayersButtonViewModel = .initial, isRecordButtonActive: Bool = false, isComposeButtonActive: Bool = false, isPlayButtonActive: Bool = false) {
        
        self.layersButton = layersButton
        self.isRecordButtonActive = isRecordButtonActive
        self.isComposeButtonActive = isComposeButtonActive
        self.isPlayButtonActive = isPlayButtonActive
    }
    
    var delegateAction: AnyPublisher<DelegateAction, Never> {
        
        delegateActionSubject.eraseToAnyPublisher()
    }
    
    func recordButtonDidTapped() {
        
        isRecordButtonActive.toggle()
        
        if isRecordButtonActive {
            
            delegateActionSubject.send(.startRecording)
            
        } else {
            
            delegateActionSubject.send(.stopRecording)
        }
    }
    
    func composeButtonDidTapped() {
        
        isComposeButtonActive.toggle()
        
        if isComposeButtonActive {
            
            delegateActionSubject.send(.startComposing)
            
        } else {
            
            delegateActionSubject.send(.stopComposing)
        }
    }
    
    func playButtonDidTapped() {
        
        isPlayButtonActive.toggle()
        
        if isPlayButtonActive {
            
            delegateActionSubject.send(.startPlaying)
            
        } else {
            
            delegateActionSubject.send(.stopPlaying)
        }
    }
}

extension ControlPanelViewModel {
    
    enum DelegateAction: Equatable {
        
        case startRecording
        case stopRecording
        case startComposing
        case stopComposing
        case startPlaying
        case stopPlaying
    }
}

final class LayersButtonViewModel {
    
    @Published var name: String
    @Published var isActive: Bool
    
    init(name: String, isActive: Bool) {
        
        self.name = name
        self.isActive = isActive
    }
    
    static let initial = LayersButtonViewModel(name: "Слои", isActive: false)
}

final class ControlPanelViewModelTests: XCTestCase {
    
    func test_recordButtonDidTapped_informsDelegateStartRecordingOnIsRecordButtonActiveWasFalse() {
        
        let sut = ControlPanelViewModel(isRecordButtonActive: false)
        let delegateActionSpy = ValueSpy(sut.delegateAction)
        
        sut.recordButtonDidTapped()
        
        XCTAssertEqual(delegateActionSpy.values, [.startRecording])
    }
    
    func test_recordButtonDidTapped_informsDelegateStopRecordingOnIsRecordButtonActiveWasTrue() {
        
        let sut = ControlPanelViewModel(isRecordButtonActive: true)
        let delegateActionSpy = ValueSpy(sut.delegateAction)
        
        sut.recordButtonDidTapped()
        
        XCTAssertEqual(delegateActionSpy.values, [.stopRecording])
    }
    
    func test_composeButtonDidTapped_informsDelegateToStartCompositingForIsComposeButtonActiveWasFalse() {
        
        let sut = ControlPanelViewModel(isComposeButtonActive: false)
        let delegateActionSpy = ValueSpy(sut.delegateAction)
        
        sut.composeButtonDidTapped()
        
        XCTAssertEqual(delegateActionSpy.values, [.startComposing])
    }
    
    func test_composeButtonDidTapped_informsDelegateToStopCompositingForIsComposeButtonActiveWasTrue() {
        
        let sut = ControlPanelViewModel(isComposeButtonActive: true)
        let delegateActionSpy = ValueSpy(sut.delegateAction)
        
        sut.composeButtonDidTapped()
        
        XCTAssertEqual(delegateActionSpy.values, [.stopComposing])
    }
    
    func test_playAllButtonDidTapped_informsDelegateToStartPlayingAllForIsPlayAllButtonActiveWasFalse() {
        
        let sut = ControlPanelViewModel(isRecordButtonActive: false)
        let delegateActionSpy = ValueSpy(sut.delegateAction)
        
        sut.playButtonDidTapped()
        
        XCTAssertEqual(delegateActionSpy.values, [.startPlaying])
    }
    
    func test_playAllButtonDidTapped_informsDelegateToStopPlayingAllForIsPlayAllButtonActiveWasTrue() {
        
        let sut = ControlPanelViewModel(isPlayButtonActive: true)
        let delegateActionSpy = ValueSpy(sut.delegateAction)
        
        sut.playButtonDidTapped()
        
        XCTAssertEqual(delegateActionSpy.values, [.stopPlaying])
    }
}
