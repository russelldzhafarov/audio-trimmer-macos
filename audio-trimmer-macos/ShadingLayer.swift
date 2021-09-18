//
//  ShadingLayer.swift
//  audio-trimmer-macos
//
//  Created by russell.dzhafarov@gmail.com on 06.09.2021.
//

import Cocoa

class ShadingLayer: CALayer {
    
    static var selectionColor: NSColor {
        NSColor.systemYellow
    }
    static var highlightColor: NSColor {
        NSColor.black.withAlphaComponent(0.5)
    }
    
    weak var viewModel: TrimmerViewModel?
    
    override func draw(in ctx: CGContext) {
        guard let viewModel = viewModel,
              viewModel.duration > .zero else { return }
        
        // Fill the highlighted range
        ctx.setFillColor(ShadingLayer.highlightColor.cgColor)
        let lowerValuePosition = CGFloat(viewModel.sliderLowerValue) * bounds.width
        let upperValuePosition = CGFloat(viewModel.sliderUpperValue) * bounds.width
        
        if lowerValuePosition > .zero {
            let rect = CGRect(x: .zero,
                              y: .zero,
                              width: lowerValuePosition,
                              height: bounds.height)
            let path = NSBezierPath(rect: rect,
                                    roundedCorners: [.topLeft, .bottomLeft],
                                    cornerRadius: 12.0)
            ctx.addPath(path.cgPath)
            ctx.fillPath()
        }
        
        if upperValuePosition < bounds.width {
            let rect = CGRect(x: upperValuePosition,
                              y: .zero,
                              width: bounds.width - upperValuePosition,
                              height: bounds.height)
            let path = NSBezierPath(rect: rect,
                                    roundedCorners: [.topRight, .bottomRight],
                                    cornerRadius: 12.0)
            ctx.addPath(path.cgPath)
            ctx.fillPath()
        }
        
        ctx.move(to: CGPoint(x: lowerValuePosition, y: .zero))
        ctx.addLine(to: CGPoint(x: upperValuePosition, y: .zero))

        ctx.move(to: CGPoint(x: lowerValuePosition, y: bounds.height))
        ctx.addLine(to: CGPoint(x: upperValuePosition, y: bounds.height))

        ctx.setLineWidth(CGFloat(4))
        ctx.setStrokeColor(ShadingLayer.selectionColor.cgColor)
        ctx.strokePath()
    }
}
