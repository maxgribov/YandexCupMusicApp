//
//  SampleSelectorViewModel.swift
//  
//
//  Created by Max Gribov on 31.10.2023.
//

import Foundation
import Combine
import Domain
import Samples

public final class SampleSelectorViewModel: ObservableObject {
    
    public let items: [SampleItemViewModel]
    public let delegateActionSubject = PassthroughSubject<DelegateAction, Never>()
    @Published public private(set) var isSampleLoading: Bool
    
    private let loadSample: (Sample.ID) -> AnyPublisher<Sample, Error>
    private var cancellable: AnyCancellable?
    
    public init(items: [SampleItemViewModel], loadSample: @escaping (Sample.ID) -> AnyPublisher<Sample, Error>) {
        
        self.items = items
        self.loadSample = loadSample
        self.isSampleLoading = false
    }
    
    public func itemDidSelected(for itemID: SampleItemViewModel.ID) {
        
        guard let item = items.first(where: { $0.id == itemID }),
              isSampleLoading == false else {
            return
        }
        
        isSampleLoading = true
        cancellable = loadSample(item.id)
            .sink(receiveCompletion: {[weak self] completion in
                
                switch completion {
                case .failure:
                    self?.delegateActionSubject.send(.failedSelectSample(item.id))
                    
                case .finished:
                    break
                }
                
            }, receiveValue: {[weak self] sample in
                
                self?.delegateActionSubject.send(.sampleDidSelected(sample))
            })
    }
}

public extension SampleSelectorViewModel {
    
    enum DelegateAction: Equatable {
        
        case sampleDidSelected(Sample)
        case failedSelectSample(Sample.ID)
    }
}
