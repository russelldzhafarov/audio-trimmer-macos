//
//  TrimmerViewController.swift
//  audio-trimmer-macos
//
//  Created by russell.dzhafarov@gmail.com on 06.09.2021.
//

import Cocoa
import Combine
import AVFoundation

class TrimmerViewController: NSViewController, TimelineViewDelegate {
    
    @IBOutlet weak var timelineView: TimelineView!
    @IBOutlet weak var playButton: NSButton!
    @IBOutlet weak var currentTimeLabel: NSTextField!
    @IBOutlet weak var startTimeLabel: NSTextField!
    @IBOutlet weak var endTimeLabel: NSTextField!
    
    let savePanel: NSSavePanel = {
        return NSSavePanel()
    }()
    
    private var audioBuffer: AVAudioPCMBuffer?
    
    private var fileFormat: AVAudioFormat?
    private var processingFormat: AVAudioFormat?
    
    private var audioPlayer: AVAudioPlayer?
    private var timer: Timer?
    
    private var cancellables: [AnyCancellable] = []
    private var error: Error? {
        didSet {
            guard let error = error else { return }
            
            let alert = NSAlert()
            alert.messageText = "Something went wrong!"
            alert.informativeText = error.localizedDescription
            alert.runModal()
        }
    }
    
    var fileURL: URL? {
        didSet {
            guard let fileURL = fileURL else { return }
            do {
                try openFile(at: fileURL)
            } catch {
                self.error = error
            }
        }
    }
    
    let viewModel = TrimmerViewModel()
    
    deinit {
        timer?.invalidate()
        timer = nil
        
        cancellables.forEach{ $0.cancel() }
        cancellables = []
    }
    
    override func viewDidAppear() {
        view.window?.isMovableByWindowBackground = true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        timelineView.delegate = self
    }
    
    @IBAction func actionTrim(_ sender: Any) {
        guard let fileURL = fileURL else { return }
        
        let exportPath = NSString(string: fileURL.lastPathComponent)
            .deletingPathExtension
            .appending("-edited")
            .appending(".m4a")
        
        savePanel.nameFieldStringValue = exportPath
        
        guard savePanel.runModal() == .OK,
              let url = savePanel.url else { return }
        
        saveFile(to: url)
    }
    
    func saveFile(to url: URL) {
        guard let audioBuffer = audioBuffer,
              let fileFormat = fileFormat,
              let processingFormat = processingFormat else { return }
        
        guard let aBuffer = audioBuffer.extract(from: viewModel.startTime, to: viewModel.endTime) else {
            error = AVError(.unknown)
            return
        }
        
        var settings = fileFormat.settings
        settings[AVFormatIDKey] = kAudioFormatMPEG4AAC
        
        do {
            let file = try AVAudioFile(forWriting: url,
                                       settings: settings,
                                       commonFormat: processingFormat.commonFormat,
                                       interleaved: processingFormat.isInterleaved)
            try file.write(from: aBuffer)
            
        } catch {
            self.error = error
        }
    }
    
    func openFile(at url: URL) throws {
        
        audioPlayer = try AVAudioPlayer(contentsOf: url)
        audioPlayer?.delegate = self
        audioPlayer?.prepareToPlay()
        
        let file = try AVAudioFile(forReading: url)
        file.framePosition = 0
        
        guard let aBuffer = AVAudioPCMBuffer(pcmFormat: file.processingFormat,
                                             frameCapacity: AVAudioFrameCount(file.length))
        else { throw AVError(.unknown) }
        
        try file.read(into: aBuffer)
        
        self.audioBuffer = aBuffer
        self.fileFormat = file.fileFormat
        self.processingFormat = file.processingFormat
        
        let duration = Double(aBuffer.frameLength) / aBuffer.format.sampleRate
        
        viewModel.duration = duration
        viewModel.samples = aBuffer.compressed()
        
        timelineView.viewModel = viewModel
        
        viewModel.$sliderLowerValue
            .receive(on: DispatchQueue.main)
            .sink { newValue in
                
                let time = newValue * self.viewModel.duration
                self.startTimeLabel.stringValue = time.hhmmss()
                
                if self.viewModel.currentTime < time {
                    self.seek(to: time)
                }
                
                self.timelineView.updateLowerHandleLayer()
                self.timelineView.updateShadingLayer()
            }
            .store(in: &cancellables)
        
        viewModel.$sliderUpperValue
            .receive(on: DispatchQueue.main)
            .sink { newValue in
                
                let time = newValue * self.viewModel.duration
                self.endTimeLabel.stringValue = time.hhmmss()
                
                if self.viewModel.currentTime > time {
                    self.seek(to: time)
                }
                
                self.timelineView.updateUpperHandleLayer()
                self.timelineView.updateShadingLayer()
            }
            .store(in: &cancellables)
        
        viewModel.$currentTime
            .receive(on: DispatchQueue.main)
            .sink { newValue in
                self.currentTimeLabel.stringValue = newValue.hhmmssms()
                
                self.timelineView.updateCursorLayer()
            }
            .store(in: &cancellables)
    }
    
    func seek(to time: TimeInterval) {
        guard let audioPlayer = audioPlayer else { return }
        
        let wasPlaying = audioPlayer.isPlaying
        if wasPlaying {
            stop()
        }
        
        viewModel.currentTime = time.clamped(to: viewModel.startTime...viewModel.endTime)
        audioPlayer.currentTime = viewModel.currentTime
        
        if wasPlaying {
            play()
        }
    }
    
    func play() {
        guard let audioPlayer = audioPlayer else { return }
        
        audioPlayer.currentTime = viewModel.currentTime
        audioPlayer.play()
        
        timer = Timer.scheduledTimer(withTimeInterval: 0.025, repeats: true) { (_) in
            guard let audioPlayer = self.audioPlayer else { return }
            
            guard audioPlayer.currentTime < self.viewModel.endTime else {
                self.actionPlay(self)
                return
            }
            
            self.viewModel.currentTime = audioPlayer.currentTime
        }
        
        playButton.image = NSImage(systemSymbolName: .pause, accessibilityDescription: "")
    }
    
    func stop() {
        audioPlayer?.stop()
        
        timer?.invalidate()
        timer = nil
        
        playButton.image = NSImage(systemSymbolName: .play, accessibilityDescription: "")
    }
    
    // MARK: - Actions
    @IBAction func actionBackward(_ sender: Any) {
        seek(to: viewModel.currentTime - 15.0)
    }
    @IBAction func actionPlay(_ sender: Any) {
        guard let audioPlayer = audioPlayer else { return }
        
        if audioPlayer.isPlaying {
            stop()
        } else {
            play()
        }
    }
    @IBAction func actionForward(_ sender: Any) {
        seek(to: viewModel.currentTime + 15.0)
    }
    @IBAction func actionReset(_ sender: Any) {
        viewModel.sliderLowerValue = viewModel.sliderMinimumValue
        viewModel.sliderUpperValue = viewModel.sliderMaximumValue
    }
}

extension TrimmerViewController: AVAudioPlayerDelegate {
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        self.error = error
        stop()
    }
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        stop()
        viewModel.currentTime = viewModel.sliderLowerValue * viewModel.duration
        audioPlayer?.currentTime = viewModel.currentTime
    }
}
