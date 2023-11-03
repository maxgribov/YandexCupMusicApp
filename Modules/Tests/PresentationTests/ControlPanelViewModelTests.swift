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
    
    init() {
        
        self.layersButton = .initial
        self.isRecordButtonActive = false
        self.isComposeButtonActive = false
        self.isPlayAllButtonActive = false
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
}
