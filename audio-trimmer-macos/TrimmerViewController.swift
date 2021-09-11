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
    
    private var cancellables: [AnyCancellable] = []
    
    var viewModel: TrimmerViewModel? { representedObject as? TrimmerViewModel }
    
    override var representedObject: Any? {
        didSet {
            guard let viewModel = representedObject as? TrimmerViewModel,
                  isViewLoaded else { return }
            
            timelineView.viewModel = viewModel
            
            viewModel.$playerState
                .receive(on: DispatchQueue.main)
                .sink { newValue in
                    switch newValue {
                    case .playing:
                        self.playButton.image = NSImage(systemSymbolName: .pause, accessibilityDescription: "")
                    case .stopped:
                        self.playButton.image = NSImage(systemSymbolName: .play, accessibilityDescription: "")
                    }
                }
                .store(in: &cancellables)
            
            viewModel.$error
                .receive(on: DispatchQueue.main)
                .sink { newValue in
                    guard let newValue = newValue else { return }
                    
                    let alert = NSAlert()
                    alert.messageText = "Something went wrong!"
                    alert.informativeText = newValue.localizedDescription
                    alert.runModal()
                }
                .store(in: &cancellables)
            
            viewModel.$sliderLowerValue
                .receive(on: DispatchQueue.main)
                .sink { newValue in
                    
                    let time = newValue * viewModel.duration
                    self.startTimeLabel.stringValue = time.hhmmss()
                    
                    if viewModel.currentTime < time {
                        self.seek(to: time)
                    }
                    
                    self.timelineView.updateLowerHandleLayer()
                    self.timelineView.updateShadingLayer()
                }
                .store(in: &cancellables)
            
            viewModel.$sliderUpperValue
                .receive(on: DispatchQueue.main)
                .sink { newValue in
                    
                    let time = newValue * viewModel.duration
                    self.endTimeLabel.stringValue = time.hhmmss()
                    
                    if viewModel.currentTime > time {
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
    }
    
    deinit {
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
    
    func seek(to time: TimeInterval) { viewModel?.seek(to: time) }
    
    @IBAction func actionTrim(_ sender: Any) {
        guard let viewModel = viewModel,
              let fileURL = viewModel.fileURL else { return }
        
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
        guard let viewModel = viewModel,
              let audioBuffer = viewModel.audioBuffer,
              let fileFormat = viewModel.fileFormat,
              let processingFormat = viewModel.processingFormat else { return }
        
        guard let aBuffer = audioBuffer.extract(from: viewModel.startTime, to: viewModel.endTime) else {
            viewModel.error = AVError(.unknown)
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
            viewModel.error = error
        }
    }
    
    // MARK: - Actions
    @IBAction func actionBackward(_ sender: Any) {
        guard let viewModel = viewModel else { return }
        viewModel.seek(to: viewModel.currentTime - 15.0)
    }
    @IBAction func actionPlay(_ sender: Any) {
        guard let viewModel = viewModel,
              let audioPlayer = viewModel.audioPlayer else { return }
        
        if audioPlayer.isPlaying {
            viewModel.stop()
        } else {
            viewModel.play()
        }
    }
    @IBAction func actionForward(_ sender: Any) {
        guard let viewModel = viewModel else { return }
        viewModel.seek(to: viewModel.currentTime + 15.0)
    }
    @IBAction func actionReset(_ sender: Any) {
        guard let viewModel = viewModel else { return }
        viewModel.sliderLowerValue = viewModel.sliderMinimumValue
        viewModel.sliderUpperValue = viewModel.sliderMaximumValue
    }
}
