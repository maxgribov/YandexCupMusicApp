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
    @Published private(set) var isRecordButtonActive: Bool
    @Published private(set) var isComposeButtonActive: Bool
    @Published private(set) var isPlayAllButtonActive: Bool
    
    private let delegateActionSubject = PassthroughSubject<DelegateAction, Never>()
    
    init() {
        
        self.layersButton = .initial
        self.isRecordButtonActive = false
        self.isComposeButtonActive = false
        self.isPlayAllButtonActive = false
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

    func test_init_correctInitialStateValues() {
        
        let sut = ControlPanelViewModel()
        
        XCTAssertEqual(sut.layersButton.name, "Слои")
        XCTAssertEqual(sut.layersButton.isActive, false)
        XCTAssertEqual(sut.isRecordButtonActive, false)
        XCTAssertEqual(sut.isComposeButtonActive, false)
        XCTAssertEqual(sut.isPlayAllButtonActive, false)
    }
    
    func test_recordButtonDidTapped_informsDelegateStartRecordingOnIsRecordButtonActiveWasFalse() {
        
        let sut = ControlPanelViewModel()
        let delegateActionSpy = ValueSpy(sut.delegateAction)
        
        sut.recordButtonDidTapped()
        
        XCTAssertEqual(delegateActionSpy.values, [.startRecording])
    }
    
    func test_recordButtonDidTapped_informsDelegateStopRecordingOnIsRecordButtonActiveWasTrue() {
        
        let sut = ControlPanelViewModel()
        let delegateActionSpy = ValueSpy(sut.delegateAction)
        
        sut.recordButtonDidTapped()
        sut.recordButtonDidTapped()
        
        XCTAssertEqual(delegateActionSpy.values, [.startRecording, .stopRecording])
    }
}
