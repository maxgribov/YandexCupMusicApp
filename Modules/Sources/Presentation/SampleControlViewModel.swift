//
//  SampleControlViewModel.swift
//  
//
//  Created by Max Gribov on 02.11.2023.
//

import Foundation
import Combine
import Domain
import CoreGraphics

public final class SampleControlViewModel: ObservableObject {
    
    @Published public private(set) var control: Layer.Control?
    private let delegateActionSubject = PassthroughSubject<DelegateAction, Never>()
    
    public init(update: AnyPublisher<Layer.Control?, Never>) {
        
        self.control = nil
        update.assign(to: &$control)
    }
    
    public var delegateAction: AnyPublisher<DelegateAction, Never> {
        
        delegateActionSubject.eraseToAnyPublisher()
    }
    
    public var isKnobPresented: Bool { control != nil }
    
    public func knobOffset(in area: CGSize) -> CGSize {
        
        guard let control else {
            return .zero
        }
        
        return Self.calculateKnobOffset(with: control, in: area)
    }
    
    public func knobPositionDidChanged(position: CGPoint, size: CGSize) {
        
        guard control != nil else {
            return
        }
        
        let controlUpdate = Self.calculateControl(forKnobPosition: position, and: size)
        delegateActionSubject.send(.controlDidUpdated(controlUpdate))
    }
}

public extension SampleControlViewModel {
    
    enum DelegateAction: Equatable {
        
        case controlDidUpdated(Layer.Control)
    }
    
    static func calculateKnobOffset(with control: Layer.Control, in area: CGSize) -> CGSize {
        
        let volume = min(max(control.volume, 0), 1)
        let speed = min(max(control.speed, 0), 1)

        let width = CGFloat(area.width * (speed - 0.5))
        let height = CGFloat(area.height * (volume - 0.5))
        
        return .init(width: width, height: height)
    }
    
    static func calculateControl(forKnobPosition position: CGPoint, and size: CGSize) -> Layer.Control {
        
        let positionY = max(position.y, 0)
        let positionX = max(position.x, 0)
        let height = max(size.height, 0)
        let width = max(size.width, 0)
        
        let volume = height <= 0 ? 0 : Double(positionY / height)
        let speed = width <= 0 ? 0 : Double(positionX / width)
        
        return .init(volume: volume, speed: speed)
    }
}
