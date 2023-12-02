//
//  VisualPlayerViewModelTests.swift
//  
//
//  Created by Yandex KZ on 02.12.2023.
//

import XCTest
import Combine
import Domain

final class VisualPlayerViewModel: ObservableObject {
    
    @Published private(set) var title: String
    private let delegateActionSubject = PassthroughSubject<DelegateAction, Never>()
    
    enum DelegateAction: Equatable {
        
        case dismiss
    }
    
    var delegateAction: AnyPublisher<DelegateAction, Never> {
        
        delegateActionSubject.eraseToAnyPublisher()
    }
    
    init(title: String) {
        self.title = title
    }
    
    func backButtonDidTapped() {
        
        delegateActionSubject.send(.dismiss)
    }

}

final class VisualPlayerViewModelTests: XCTestCase {
    
    func test_init_titleEqualTrackName() {
        
        let sut = VisualPlayerViewModel(title: "track name")
        
        XCTAssertEqual(sut.title, "track name")
    }
    
    func test_backButtonDidTap_messgesDelegateToDissmiss() {
        
        let sut = VisualPlayerViewModel(title: "track name")
        let delegateActionSpy = ValueSpy(sut.delegateAction)
        
        sut.backButtonDidTapped()
        
        XCTAssertEqual(delegateActionSpy.values, [.dismiss])
    }
}
