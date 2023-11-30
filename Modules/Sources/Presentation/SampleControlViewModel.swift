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
    
    public init(initial control: Layer.Control? = nil, update: AnyPublisher<Layer.Control?, Never>) {
        
        self.control = control
        update.assign(to: &$control)
    }
    
    public var delegateAction: AnyPublisher<DelegateAction, Never> {
        
        delegateActionSubject.eraseToAnyPublisher()
    }
    
    public var isKnobPresented: Bool { control != nil }
    
    public func knobOffset(with control: Layer.Control?, in area: CGSize) -> CGSize {
        
        guard let control else {
            return .zero
        }
        
        return Self.calculateKnobOffset(with: control, in: area)
    }
    
    public func knobOffsetDidChanged(offset: CGSize, area: CGSize) {
        
        guard control != nil else {
            return
        }
        
        let controlUpdate = Self.calculateControl(forKnobOffset: offset, in: area)
        delegateActionSubject.send(.controlDidUpdated(controlUpdate))
    }
}

public extension SampleControlViewModel {
    
    enum DelegateAction: Equatable {
        
        case controlDidUpdated(Layer.Control)
    }
    
    static func calculateKnobOffset(with control: Layer.Control, in area: CGSize) -> CGSize {
        
        let volume = 1 - min(max(control.volume, 0), 1)
        let speed = min(max(control.speed, 0), 1)

        let width = CGFloat(area.width * (speed - 0.5))
        let height = CGFloat(area.height * (volume - 0.5))
        
        return .init(width: width, height: height)
    }
    
    static func calculateControl(forKnobOffset offset: CGSize, in area: CGSize) -> Layer.Control {
        
        let areaWidth = abs(area.width)
        let areaHeight = abs(area.height)
        let offsetLimited = offset.limit(area: area)
        
        let speed = areaWidth > 0 ? ((areaWidth / 2) + offsetLimited.width ) / areaWidth : 0
        let volume = areaHeight > 0 ? ((areaHeight / 2) - offsetLimited.height ) / areaHeight : 0

        return .init(volume: volume, speed: speed)
    }
}
