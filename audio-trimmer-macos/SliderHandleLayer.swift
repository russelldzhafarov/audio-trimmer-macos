//
//  SliderHandleLayer.swift
//  audio-trimmer-macos
//
//  Created by russell.dzhafarov@gmail.com on 06.09.2021.
//

import Cocoa

class SliderHandleLayer: CALayer {
    
    static var selectionColor: NSColor {
        NSColor.systemYellow
    }
    
    var roundedCorners: NSBezierPath.Corners = [] {
        didSet {
            setNeedsDisplay()
        }
    }
    
    weak var viewModel: TrimmerViewModel?
    
    override func draw(in ctx: CGContext) {
        guard let viewModel = viewModel,
              viewModel.duration > .zero else { return }
        
        let path = NSBezierPath(rect: bounds, roundedCorners: roundedCorners, cornerRadius: CGFloat(16))
        ctx.addPath(path.cgPath)
        ctx.setFillColor(SliderHandleLayer.selectionColor.cgColor)
        ctx.fillPath()

        // Draw two middle lines
        ctx.move(to: CGPoint(x: bounds.midX - 1.0,
                             y: bounds.midY - 6.0))
        ctx.addLine(to: CGPoint(x: bounds.midX - 1.0,
                                y: bounds.midY + 6.0))

        ctx.move(to: CGPoint(x: bounds.midX + 1.0,
                             y: bounds.midY - 6.0))
        ctx.addLine(to: CGPoint(x: bounds.midX + 1.0,
                                y: bounds.midY + 6.0))

        ctx.setLineCap(.round)
        ctx.setLineWidth(CGFloat(1))
        ctx.setStrokeColor(NSColor.black.withAlphaComponent(CGFloat(0.8)).cgColor)
        ctx.strokePath()
    }
}
