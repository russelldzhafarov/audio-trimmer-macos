//
//  CursorLayer.swift
//  audio-trimmer-macos
//
//  Created by russell.dzhafarov@gmail.com on 06.09.2021.
//

import Cocoa

class CursorLayer: CALayer {
    
    static var cursorColor: NSColor {
        NSColor.systemRed
    }
    
    var viewModel: TrimmerViewModel?
    
    override func draw(in ctx: CGContext) {
        guard let viewModel = viewModel,
              viewModel.duration > .zero else { return }
        
        ctx.setLineWidth(1.0)
        ctx.setStrokeColor(CursorLayer.cursorColor.cgColor)
        ctx.move(to: CGPoint(x: bounds.midX, y: .zero))
        ctx.addLine(to: CGPoint(x: bounds.midX, y: bounds.height))
        ctx.strokePath()
    }
}
