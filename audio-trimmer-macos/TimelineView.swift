//
//  RangeSlider.swift
//  audio-trimmer-macos
//
//  Created by russell.dzhafarov@gmail.com on 06.09.2021.
//

import Cocoa
import Combine

extension Comparable {
    func clamped(to limits: ClosedRange<Self>) -> Self {
        return min(max(self, limits.lowerBound), limits.upperBound)
    }
}

protocol TimelineViewDelegate: class {
    func seek(to time: TimeInterval)
}

class TimelineView: NSView, ObservableObject {
    
    weak var delegate: TimelineViewDelegate?
    
    override var mouseDownCanMoveWindow: Bool { false }
    override var isFlipped: Bool { true }
    
    override var frame: CGRect {
        didSet {
            updateLayerFrames()
        }
    }
    
    var viewModel: TrimmerViewModel? {
        didSet {
            waveformLayer.viewModel = viewModel
            shadingLayer.viewModel = viewModel
            lowerHandleLayer.viewModel = viewModel
            upperHandleLayer.viewModel = viewModel
            cursorLayer.viewModel = viewModel
            rulerLayer.viewModel = viewModel
            
            updateLayerFrames()
        }
    }
    
    let waveformLayer = WaveformLayer()
    let shadingLayer = ShadingLayer()
    let lowerHandleLayer = SliderHandleLayer()
    let upperHandleLayer = SliderHandleLayer()
    let cursorLayer = CursorLayer()
    let rulerLayer = RulerLayer()
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    func setup() {
        wantsLayer = true
        let contentsScale: CGFloat = NSScreen.main?.backingScaleFactor ?? CGFloat(1)
        
        let rootLayer = CALayer()
        
        waveformLayer.contentsScale = contentsScale
        rootLayer.addSublayer(waveformLayer)
        
        rulerLayer.contentsScale = contentsScale
        rootLayer.addSublayer(rulerLayer)
        
        shadingLayer.contentsScale = contentsScale
        rootLayer.addSublayer(shadingLayer)
        
        lowerHandleLayer.roundedCorners = [.topLeft, .bottomLeft]
        lowerHandleLayer.contentsScale = contentsScale
        rootLayer.addSublayer(lowerHandleLayer)
        
        upperHandleLayer.roundedCorners = [.topRight, .bottomRight]
        upperHandleLayer.contentsScale = contentsScale
        rootLayer.addSublayer(upperHandleLayer)
        
        cursorLayer.contentsScale = contentsScale
        rootLayer.addSublayer(cursorLayer)
        
        layer = rootLayer
    }
    
    func updateCursorLayer() {
        guard let viewModel = viewModel,
              viewModel.duration > .zero else { return }
        
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        
        let oneSecWidth = (bounds.width - viewModel.thumbWidth * 2.0) / CGFloat(viewModel.duration)
        let cursorPos = viewModel.thumbWidth + CGFloat(viewModel.currentTime) * oneSecWidth
        cursorLayer.frame = NSRect(x: cursorPos,
                                   y: viewModel.rulerHeight + 2.0,
                                   width: 1.0,
                                   height: bounds.height - viewModel.rulerHeight - 4.0)
        cursorLayer.setNeedsDisplay()
        
        CATransaction.commit()
    }
    
    func updateRulerLayer() {
        guard let viewModel = viewModel,
              viewModel.duration > .zero else { return }
        
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        
        rulerLayer.frame = CGRect(x: viewModel.thumbWidth,
                                  y: .zero,
                                  width: bounds.width - viewModel.thumbWidth * 2.0,
                                  height: viewModel.rulerHeight - 6.0)
        rulerLayer.setNeedsDisplay()
        
        CATransaction.commit()
    }
    
    func updateWaveformLayer() {
        guard let viewModel = viewModel,
              viewModel.duration > .zero else { return }
        
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        
        waveformLayer.frame = CGRect(x: viewModel.thumbWidth,
                                     y: viewModel.rulerHeight,
                                     width: bounds.width - viewModel.thumbWidth * 2.0,
                                     height: bounds.height - viewModel.rulerHeight)
        waveformLayer.setNeedsDisplay()
        
        CATransaction.commit()
    }
    
    func updateShadingLayer() {
        guard let viewModel = viewModel,
              viewModel.duration > .zero else { return }
        
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        
        shadingLayer.frame = CGRect(x: viewModel.thumbWidth,
                                    y: viewModel.rulerHeight,
                                    width: bounds.width - viewModel.thumbWidth * 2.0,
                                    height: bounds.height - viewModel.rulerHeight)
        shadingLayer.setNeedsDisplay()
        
        CATransaction.commit()
    }
    
    func updateLowerHandleLayer() {
        guard let viewModel = viewModel,
              viewModel.duration > .zero else { return }
        
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        
        let lowerThumbCenter = viewModel.thumbWidth + (bounds.width - viewModel.thumbWidth * 2.0) * CGFloat(viewModel.sliderLowerValue)
        
        lowerHandleLayer.frame = CGRect(x: lowerThumbCenter - viewModel.thumbWidth,
                                        y: viewModel.rulerHeight,
                                        width: viewModel.thumbWidth,
                                        height: bounds.height - viewModel.rulerHeight)
        lowerHandleLayer.setNeedsDisplay()
        
        CATransaction.commit()
    }
    
    func updateUpperHandleLayer() {
        guard let viewModel = viewModel,
              viewModel.duration > .zero else { return }
        
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        
        let upperThumbCenter = viewModel.thumbWidth + (bounds.width - viewModel.thumbWidth * 2.0) * CGFloat(viewModel.sliderUpperValue)
        upperHandleLayer.frame = CGRect(x: upperThumbCenter,
                                        y: viewModel.rulerHeight,
                                        width: viewModel.thumbWidth,
                                        height: bounds.height - viewModel.rulerHeight)
        upperHandleLayer.setNeedsDisplay()
        
        CATransaction.commit()
    }
    
    func updateLayerFrames() {
        guard let viewModel = viewModel,
              viewModel.duration > .zero else { return }
        
        updateRulerLayer()
        updateWaveformLayer()
        updateShadingLayer()
        updateLowerHandleLayer()
        updateUpperHandleLayer()
        updateCursorLayer()
    }
    
    func position(for value: Double) -> CGFloat {
        guard let viewModel = viewModel,
              viewModel.duration > .zero else { return .zero }
        
        return bounds.width * CGFloat(value)
    }
    
    override func mouseDown(with event: NSEvent) {
        guard let viewModel = viewModel,
              viewModel.duration > .zero else { return }
        
        let loc = convert(event.locationInWindow, from: nil)
        
        // Hit test the layers
        if lowerHandleLayer.frame.contains(loc) {
            moveLowerSlider(with: event)
            
        } else if upperHandleLayer.frame.contains(loc) {
            moveUpperSlider(with: event)
            
        } else {
            moveCursor(with: event)
        }
    }
    
    func moveCursor(with event: NSEvent) {
        guard let viewModel = viewModel else { return }
        
        while true {
            guard let nextEvent = window?.nextEvent(matching: [.leftMouseUp, .leftMouseDragged]) else { continue }
            
            let end = convert(nextEvent.locationInWindow, from: nil)
            let endTime = (viewModel.duration * Double(end.x - viewModel.thumbWidth)) / Double(bounds.width - viewModel.thumbWidth * 2.0)
            
            viewModel.currentTime = endTime.clamped(to: (viewModel.sliderLowerValue * viewModel.duration)...(viewModel.sliderUpperValue * viewModel.duration))
            
            if nextEvent.type == .leftMouseUp {
                delegate?.seek(to: viewModel.currentTime)
                break
            }
        }
    }
    
    func moveLowerSlider(with event: NSEvent) {
        guard let viewModel = viewModel else { return }
        
        var prevLoc = convert(event.locationInWindow, from: nil)
        
        while true {
            guard let nextEvent = window?.nextEvent(matching: [.leftMouseUp, .leftMouseDragged]) else { continue }
            
            let loc = convert(nextEvent.locationInWindow, from: nil)
            
            // 1. Determine by how much the user has dragged
            let deltaLocation = Double(loc.x - prevLoc.x)
            let deltaValue = (viewModel.sliderMaximumValue - viewModel.sliderMinimumValue) * deltaLocation / Double(bounds.width)
            
            prevLoc = loc
            
            // 2. Update the values
            viewModel.sliderLowerValue = (viewModel.sliderLowerValue + deltaValue).clamped(to: viewModel.sliderMinimumValue...viewModel.sliderUpperValue)
            
            if nextEvent.type == .leftMouseUp {
                break
            }
        }
    }
    func moveUpperSlider(with event: NSEvent) {
        guard let viewModel = viewModel else { return }
        
        var prevLoc = convert(event.locationInWindow, from: nil)
        
        while true {
            guard let nextEvent = window?.nextEvent(matching: [.leftMouseUp, .leftMouseDragged]) else { continue }
            
            let loc = convert(nextEvent.locationInWindow, from: nil)
            
            // 1. Determine by how much the user has dragged
            let deltaLocation = Double(loc.x - prevLoc.x)
            let deltaValue = (viewModel.sliderMaximumValue - viewModel.sliderMinimumValue) * deltaLocation / Double(bounds.width)
            
            prevLoc = loc
            
            // 2. Update the values
            viewModel.sliderUpperValue = (viewModel.sliderUpperValue + deltaValue).clamped(to: viewModel.sliderLowerValue...viewModel.sliderMaximumValue)
            
            if nextEvent.type == .leftMouseUp {
                break
            }
        }
    }
}

