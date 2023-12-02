//
//  VisualPlayerViewModel.swift
//
//
//  Created by Yandex KZ on 02.12.2023.
//

import Foundation
import Combine
import Domain

public final class VisualPlayerViewModel: ObservableObject, Hashable {
    
    public private(set) var layerID: Layer.ID
    @Published public private(set) var title: String
    @Published public private(set) var shapes: [VisualPlayerShapeViewModel]
    @Published public private(set) var canvasArea: CGRect
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
    
    public init(layerID: Layer.ID, title: String, makeShapes: @escaping (Layer.ID) -> [VisualPlayerShapeViewModel], canvasArea: CGRect, audioControl: VisualPlayerAudioControlViewModel, trackUpdates: AnyPublisher<Float, Never>, playerStateUpdates: AnyPublisher<PlayerState, Never>) {
        
        self.layerID = layerID
        self.title = title
        self.shapes = makeShapes(layerID)
        self.canvasArea = canvasArea
        self.audioControl = audioControl
        self.makeShapes = makeShapes
        
        trackUpdates
            .combineLatest(self.$canvasArea)
            .sink { [unowned self] update, area in
                
                shapes.forEach { shape in
                    shape.update(update, area: area)
                }
                
            }.store(in: &cancellables)
        
        playerStateUpdates
            .sink { [unowned self] state in
                
                self.audioControl.playButton.isPlaying = state.isPlaying
                
            }.store(in: &cancellables)
        
        Timer.publish(every: 0.1, on: .main, in: .common)
            .autoconnect()
            .sink { [unowned self] _ in
                
                shapes.forEach { shape in
                    shape.updatePositon(for: canvasArea)
                }
                
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
    
    public func canvasAreaDidUpdated(area: CGRect) {
        
        canvasArea = area
    }
    
    public static func == (lhs: VisualPlayerViewModel, rhs: VisualPlayerViewModel) -> Bool {
        lhs.layerID == rhs.layerID
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(layerID)
    }
}

open class VisualPlayerShapeViewModel: Identifiable {
    
    public let id: UUID
    public let name: String
    @Published public var scale: CGFloat
    @Published public var position: CGPoint
    public private(set) var direction: Direction
    
    public init(id: UUID, name: String, scale: CGFloat, position: CGPoint, direction: Direction = .down) {
        
        self.id = id
        self.name = name
        self.scale = scale
        self.position = position
        self.direction = direction
    }
    
    open func update(_ data: Float, area: CGRect) {
        
        
    }
    
    open func updatePositon(for area: CGRect) {
        
        let offset: CGFloat = 10
        let halfSize: CGFloat = 256 / 2
        switch direction {
        case .up:
            position = CGPoint(x: position.x, y: position.y - offset)
            if position.y < area.minY + halfSize {
                direction = randomDirection()
            }
            
        case .down:
            position = CGPoint(x: position.x, y: position.y + offset)
            if position.y > area.maxY - halfSize {
                direction = randomDirection()
            }
            
        case .left:
            position = CGPoint(x: position.x - offset, y: position.y)
            if position.y < area.minX + halfSize {
                direction = randomDirection()
            }
            
        case .rigth:
            position = CGPoint(x: position.x + offset, y: position.y)
            if position.x > area.maxX - halfSize {
                direction = randomDirection()
            }
        }
    }
    
    private func randomDirection() -> Direction {
        
        Direction.allCases.randomElement() ?? .down
    }
    
    public enum Direction: CaseIterable {
        
        case up
        case down
        case left
        case rigth
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
