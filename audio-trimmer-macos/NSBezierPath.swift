//
//  NSBezierPath.swift
//  audio-trimmer-macos
//
//  Created by russell.dzhafarov@gmail.com on 06.09.2021.
//

import AppKit

extension NSBezierPath {
    struct Corners: OptionSet {
        let rawValue: Int
        
        static let topLeft = Corners(rawValue: 1 << 0)
        static let bottomLeft = Corners(rawValue: 1 << 1)
        static let topRight = Corners(rawValue: 1 << 2)
        static let bottomRight = Corners(rawValue: 1 << 3)
    }
    
    convenience init(rect: CGRect, roundedCorners: NSBezierPath.Corners, cornerRadius: CGFloat) {
        self.init()
        
        let bottomRightCorner = CGPoint(x: rect.maxX, y: rect.minY)
        
        move(to: bottomRightCorner)
        
        if roundedCorners.contains(.bottomRight) {
            line(to: CGPoint(x: rect.maxX - cornerRadius, y: rect.minY))
            curve(to: CGPoint(x: rect.maxX, y: rect.minY + cornerRadius),
                  controlPoint1: bottomRightCorner,
                  controlPoint2: bottomRightCorner)
        } else {
            line(to: bottomRightCorner)
        }
        
        let topRightCorner = CGPoint(x: rect.maxX, y: rect.maxY)
        
        if roundedCorners.contains(.topRight) {
            line(to: CGPoint(x: rect.maxX, y: rect.maxY - cornerRadius))
            curve(to: CGPoint(x: rect.maxX - cornerRadius, y: rect.maxY),
                  controlPoint1: topRightCorner,
                  controlPoint2: topRightCorner)
        } else {
            line(to: topRightCorner)
        }
        
        let topLeftCorner = CGPoint(x: rect.minX, y: rect.maxY)
        
        if roundedCorners.contains(.topLeft) {
            line(to: CGPoint(x: rect.minX + cornerRadius, y: rect.maxY))
            curve(to: CGPoint(x: rect.minX, y: rect.maxY - cornerRadius),
                  controlPoint1: topLeftCorner,
                  controlPoint2: topLeftCorner)
        } else {
            line(to: topLeftCorner)
        }
        
        let bottomLeftCorner = CGPoint(x: rect.minX, y: rect.minY)
        
        if roundedCorners.contains(.bottomLeft) {
            line(to: CGPoint(x: rect.minX, y: rect.minY + cornerRadius))
            curve(to: CGPoint(x: rect.minX + cornerRadius, y: rect.minY),
                  controlPoint1: bottomLeftCorner,
                  controlPoint2: bottomLeftCorner)
        } else {
            line(to: bottomLeftCorner)
        }
    }
    
    var cgPath: CGPath {
        let path = CGMutablePath()
        var points = [CGPoint](repeating: .zero, count: 3)
        
        for i in 0 ..< self.elementCount {
            let type = self.element(at: i, associatedPoints: &points)
            
            switch type {
            case .moveTo:
                path.move(to: points[0])
                
            case .lineTo:
                path.addLine(to: points[0])
                
            case .curveTo:
                path.addCurve(to: points[2], control1: points[0], control2: points[1])
                
            case .closePath:
                path.closeSubpath()
                
            @unknown default:
                break
            }
        }
        return path
    }
}
