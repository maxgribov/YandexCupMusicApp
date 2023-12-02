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
        case togglePlay
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
        
        let sut = makeSUT(title: "track name")
        
        XCTAssertEqual(sut.title, "track name")
    }
    
    func test_backButtonDidTap_messgesDelegateToDissmiss() {
        
        let sut = makeSUT()
        let delegateActionSpy = ValueSpy(sut.delegateAction)
        
        sut.backButtonDidTapped()
        
        XCTAssertEqual(delegateActionSpy.values, [.dismiss])
    }
    
    //MARK: - Helpers
    
    func makeSUT(
        title: String = "",
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> VisualPlayerViewModel {
        
        let sut = VisualPlayerViewModel(title: title)
        trackForMemoryLeaks(sut, file: file, line: line)
        
        return sut
    }
}
