//
//  TrimmerViewModel.swift
//  audio-trimmer-macos
//
//  Created by russell.dzhafarov@gmail.com on 06.09.2021.
//

import Cocoa
import Combine

class TrimmerViewModel: ObservableObject {
    
    let thumbWidth = CGFloat(12)
    let rulerHeight = CGFloat(32)
    
    let sliderMinimumValue: Double = .zero
    let sliderMaximumValue: Double = 1.0
    
    @Published var sliderLowerValue: Double = .zero
    @Published var sliderUpperValue: Double = 1.0
    
    @Published var currentTime: TimeInterval = .zero
    @Published var duration: TimeInterval = .zero
    
    var samples: [Float] = []
    
    var startTime: TimeInterval { sliderLowerValue * duration }
    var endTime: TimeInterval { sliderUpperValue * duration }
}
