//
//  VisualPlayerViewModel.swift
//
//
//  Created by Yandex KZ on 02.12.2023.
//

import Foundation
import Combine
import Domain

public final class VisualPlayerViewModel: ObservableObject {
    
    public private(set) var layerID: Layer.ID
    @Published public private(set) var title: String
    @Published public private(set) var shapes: [VisualPlayerShapeViewModel]
    public let audioControl: VisualPlayerAudioControlViewModel
    
    private let delegateActionSubject = PassthroughSubject<DelegateAction, Never>()
    private let makeShapes: (Layer.ID) -> [VisualPlayerShapeViewModel]
    private var cancellables = Set<AnyCancellable>()
    
    public enum DelegateAction: Equatable {
        
        case dismiss
        case togglePlay
        case rewind
        case fastForward
        case export
    }
    
    public var delegateAction: AnyPublisher<DelegateAction, Never> {
        
        delegateActionSubject.eraseToAnyPublisher()
    }
    
    public init(layerID: Layer.ID, title: String, makeShapes: @escaping (Layer.ID) -> [VisualPlayerShapeViewModel], audioControl: VisualPlayerAudioControlViewModel, trackUpdates: AnyPublisher<Float, Never>, playerStateUpdates: AnyPublisher<PlayerState, Never>) {
        
        self.layerID = layerID
        self.title = title
        self.shapes = makeShapes(layerID)
        self.audioControl = audioControl
        self.makeShapes = makeShapes
        
        trackUpdates
            .sink { [unowned self] update in
                
                shapes.forEach { shape in
                    shape.update(update, area: .zero)
                }
                
            }.store(in: &cancellables)
        
        playerStateUpdates
            .sink { [unowned self] state in
                
                self.audioControl.playButton.isPlaying = state.isPlaying
                
            }.store(in: &cancellables)
    }
    
    public func backButtonDidTapped() {
        
        delegateActionSubject.send(.dismiss)
    }
    
    public func playButtonDidTapped() {
        
        delegateActionSubject.send(.togglePlay)
    }
    
    public func rewindButtonDidTapped() {
        
        delegateActionSubject.send(.rewind)
    }
    
    public func fastForwardButtonDidTapped() {
        
        delegateActionSubject.send(.fastForward)
    }

    public func exportButtonDidTapped() {
        
        delegateActionSubject.send(.export)
    }
}

open class VisualPlayerShapeViewModel: Identifiable {
    
    public let id: UUID
    public let name: String
    @Published public var scale: CGFloat
    @Published public var position: CGPoint
    
    public init(id: UUID, name: String, scale: CGFloat, position: CGPoint) {
        
        self.id = id
        self.name = name
        self.scale = scale
        self.position = position
    }
    
    open func update(_ data: Float, area: CGRect) {
        
        
    }
}

public final class VisualPlayerAudioControlViewModel {
    
    public let playButton: PlayButtonVewModel
    
    public init(playButton: PlayButtonVewModel) {
        self.playButton = playButton
    }
}

public final class PlayButtonVewModel: ObservableObject {
    
    @Published public var isPlaying: Bool
    
    public init(isPlaying: Bool) {
        
        self.isPlaying = isPlaying
    }
}

public struct PlayerState: Equatable {
    
    public let isPlaying: Bool
    public let duration: Double
    public let played: Double
    
    public  init(isPlaying: Bool, duration: Double, played: Double) {
        self.isPlaying = isPlaying
        self.duration = duration
        self.played = played
    }
}
