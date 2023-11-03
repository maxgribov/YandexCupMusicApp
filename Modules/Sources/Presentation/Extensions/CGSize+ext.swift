//
//  CGSize+ext.swift
//
//
//  Created by Max Gribov on 03.11.2023.
//

import CoreGraphics

public extension CGSize {
    
    func offset(translation: CGSize) -> CGSize {
        
        let newOffset = CGSize(width: width + translation.width ,
                               height: height + translation.height)
        
        return newOffset
    }
    
    func limit(area: CGSize) -> CGSize {
        
        let halfAreaWidth = abs(area.width / 2)
        let halfAreaHeight = abs(area.height / 2)
        
        let updatedWidth = min(abs(width), halfAreaWidth) * (width.sign == .minus ? -1 : 1)
        let updatedHeight = min(abs(height), halfAreaHeight) * (height.sign == .minus ? -1 : 1)
        
        return .init(width: updatedWidth, height: updatedHeight)
    }
}
