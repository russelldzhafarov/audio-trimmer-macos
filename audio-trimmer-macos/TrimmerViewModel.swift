//
//  TrimmerViewModel.swift
//  audio-trimmer-macos
//
//  Created by russell.dzhafarov@gmail.com on 06.09.2021.
//

import Cocoa
import Combine
import AVFoundation

class TrimmerViewModel: NSObject, ObservableObject {
    
    let thumbWidth = CGFloat(12)
    let rulerHeight = CGFloat(32)
    
    let sliderMinimumValue: Double = .zero
    let sliderMaximumValue: Double = 1.0
    
    enum PlayerState {
        case playing, stopped
    }
    
    @Published var playerState: PlayerState = .stopped
    
    @Published var sliderLowerValue: Double = .zero
    @Published var sliderUpperValue: Double = 1.0
    
    @Published var currentTime: TimeInterval = .zero
    @Published var duration: TimeInterval = .zero
    
    @Published var error: Error?
    
    var samples: [Float] = []
    
    var startTime: TimeInterval { sliderLowerValue * duration }
    var endTime: TimeInterval { sliderUpperValue * duration }
    
    var fileURL: URL?
    var audioBuffer: AVAudioPCMBuffer?
    
    var fileFormat: AVAudioFormat?
    var processingFormat: AVAudioFormat?
    
    var audioPlayer: AVAudioPlayer? {
        didSet {
            audioPlayer?.delegate = self
        }
    }
    var timer: Timer?
    
    deinit {
        timer?.invalidate()
        timer = nil
    }
    
    func seek(to time: TimeInterval) {
        guard let audioPlayer = audioPlayer else { return }
        
        let wasPlaying = audioPlayer.isPlaying
        if wasPlaying {
            stop()
        }
        
        currentTime = time.clamped(to: startTime...endTime)
        audioPlayer.currentTime = currentTime
        
        if wasPlaying {
            play()
        }
    }
    
    func play() {
        guard let audioPlayer = audioPlayer else { return }
        
        audioPlayer.currentTime = currentTime
        audioPlayer.play()
        
        timer = Timer.scheduledTimer(withTimeInterval: 0.025, repeats: true) { (_) in
            guard audioPlayer.currentTime < self.endTime else {
                self.stop()
                return
            }
            
            self.currentTime = audioPlayer.currentTime
        }
        
        playerState = .playing
    }
    
    func stop() {
        guard let audioPlayer = audioPlayer else { return }
        
        audioPlayer.stop()
        
        timer?.invalidate()
        timer = nil
        
        playerState = .stopped
    }
    
    func power(at time: TimeInterval) -> Float {
        guard duration > .zero else { return .zero }
        
        let sampleRate = Double(samples.count) / duration
        
        let index = Int(time * sampleRate)
        
        guard samples.indices.contains(index) else { return .zero }
        
        let power = samples[index]
        
        let avgPower = 20 * log10(power)
        
        return scaledPower(power: avgPower)
    }
    
    func scaledPower(power: Float) -> Float {
        guard power.isFinite else {
            return .zero
        }
        
        let minDb: Float = -80
        
        if power < minDb {
            return .zero
            
        } else if power >= 1.0 {
            return 1.0
            
        } else {
            return (abs(minDb) - abs(power)) / abs(minDb)
        }
    }
}

extension TrimmerViewModel: AVAudioPlayerDelegate {
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        self.error = error
        stop()
    }
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        stop()
        
        currentTime = sliderLowerValue * duration
        audioPlayer?.currentTime = currentTime
    }
}
