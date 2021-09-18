//
//  RulerLayer.swift
//  audio-trimmer-macos
//
//  Created by russell.dzhafarov@gmail.com on 06.09.2021.
//

import Cocoa

class RulerLayer: CALayer {
    
    static var rulerColor: NSColor {
        NSColor.white.withAlphaComponent(0.4)
    }
    static var rulerLabelColor: NSColor {
        NSColor.white.withAlphaComponent(0.4)
    }
    
    weak var viewModel: TrimmerViewModel?
    
    let attributes: [NSAttributedString.Key: Any] = [
        .foregroundColor: RulerLayer.rulerLabelColor,
        .font: NSFont.systemFont(ofSize: CGFloat(12))
    ]
    
    override func draw(in ctx: CGContext) {
        guard let viewModel = viewModel,
              viewModel.duration > .zero else { return }
        
        let startTime = TimeInterval.zero
        let endTime = viewModel.duration
        let visibleDur = endTime - startTime
        
        let oneSecWidth = bounds.width / CGFloat(visibleDur)
        
        let step: TimeInterval
        switch oneSecWidth {
        case 0 ..< 5:
            let koeff = Double(bounds.width) / Double(85)
            step = max(10, (visibleDur / koeff).round(nearest: 10))
            
        case 5 ..< 10: step = 15
        case 10 ..< 15: step = 10
        case 15 ..< 50: step = 5
        case 50 ..< 100: step = 3
        case 100 ..< 200: step = 1
        case 200 ..< 300: step = 0.5
        default: step = 0.25
        }
        
        drawTicks(to: ctx,
                  startPos: .zero,
                  startTime: startTime,
                  endTime: endTime,
                  stepInSec: step / 10.0,
                  stepInPx: oneSecWidth * CGFloat(step) / 10.0,
                  height: 6.0,
                  drawLabel: false,
                  lineWidth: 1.0,
                  minY: bounds.maxY - 4.0,
                  maxY: bounds.maxY)
        
        drawTicks(to: ctx,
                  startPos: .zero,
                  startTime: startTime,
                  endTime: endTime,
                  stepInSec: step,
                  stepInPx: oneSecWidth * CGFloat(step),
                  height: 10.0,
                  drawLabel: true,
                  lineWidth: 1.0,
                  minY: bounds.maxY - 8.0,
                  maxY: bounds.maxY - 4.0)
    }
    
    private func drawTicks(to ctx: CGContext, startPos: CGFloat, startTime: TimeInterval, endTime: TimeInterval, stepInSec: TimeInterval, stepInPx: CGFloat, height: CGFloat, drawLabel: Bool, lineWidth: CGFloat, minY: CGFloat, maxY: CGFloat) {
        
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(cgContext: ctx, flipped: true)
        
        var x = startPos
        for time in stride(from: startTime, to: endTime, by: stepInSec) {
            
            if drawLabel {
                NSString(string: stepInSec < 1 ? time.mmssms() : time.mmss())
                    .draw(at: NSPoint(x: x, y: .zero),
                          withAttributes: attributes)
            }
            
            ctx.move(to: CGPoint(x: x, y: minY))
            ctx.addLine(to: CGPoint(x: x, y: maxY))
            
            x += stepInPx
        }
        
        ctx.setLineWidth(lineWidth)
        ctx.setStrokeColor(RulerLayer.rulerColor.cgColor)
        ctx.strokePath()
        
        NSGraphicsContext.restoreGraphicsState()
    }
}
