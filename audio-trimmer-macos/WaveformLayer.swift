//
//  WaveformLayer.swift
//  audio-trimmer-macos
//
//  Created by russell.dzhafarov@gmail.com on 06.09.2021.
//

import Cocoa

class WaveformLayer: CALayer {
    
    static var waveformColor: NSColor {
        NSColor.white.withAlphaComponent(0.8)
    }
    
    weak var viewModel: TrimmerViewModel?
    
    override func draw(in ctx: CGContext) {
        guard let viewModel = viewModel,
              viewModel.duration > .zero else { return }
        
        let duration = viewModel.duration
        
        guard duration > .zero else { return }
        
        let oneSecWidth = bounds.width / CGFloat(duration)
        
        let frame = CGRect(x: .zero,
                           y: .zero,
                           width: CGFloat(duration) * oneSecWidth,
                           height: bounds.height)
        
        let lineWidth = CGFloat(1)
        let stepInPx = CGFloat(1)
        
        let koeff = frame.width / stepInPx
        let stepInSec = duration / Double(koeff)
        
        guard stepInSec > 0 else { return }
        
        var x = frame.origin.x
        for time in stride(from: .zero, to: duration, by: stepInSec) {
            let power = viewModel.power(at: time)
            
            let heigth = max(CGFloat(1),
                             CGFloat(power) * (frame.height/2))
            
            ctx.move(to: CGPoint(x: x,
                                 y: frame.midY + heigth))
            
            ctx.addLine(to: CGPoint(x: x,
                                    y: frame.midY - heigth))
            
            x += stepInPx
        }
        
        ctx.setLineWidth(lineWidth)
        ctx.setStrokeColor(WaveformLayer.waveformColor.cgColor)
        ctx.strokePath()
    }
}
