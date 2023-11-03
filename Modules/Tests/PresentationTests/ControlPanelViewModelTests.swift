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
    @Published var isPlayAllButtonActive: Bool
    
    private let delegateActionSubject = PassthroughSubject<DelegateAction, Never>()
    
    init(layersButton: LayersButtonViewModel = .initial, isRecordButtonActive: Bool = false, isComposeButtonActive: Bool = false, isPlayAllButtonActive: Bool = false) {
        
        self.layersButton = layersButton
        self.isRecordButtonActive = isRecordButtonActive
        self.isComposeButtonActive = isComposeButtonActive
        self.isPlayAllButtonActive = isPlayAllButtonActive
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
}

extension ControlPanelViewModel {
    
    enum DelegateAction: Equatable {
        
        case startRecording
        case stopRecording
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
        
        let sut = ControlPanelViewModel()
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
}
