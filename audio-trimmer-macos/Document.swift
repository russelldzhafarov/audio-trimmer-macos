//
//  Document.swift
//  audio-trimmer-macos
//
//  Created by russell.dzhafarov@gmail.com on 06.09.2021.
//

import Cocoa
import AVFoundation

class Document: NSDocument {
    
    let viewModel = TrimmerViewModel()
    
    override var isDocumentEdited: Bool { false }
    // This disables auto save.
    override class var autosavesInPlace: Bool { false }
    // This enables asynchronous reading.
    override class func canConcurrentlyReadDocuments(ofType typeName: String) -> Bool { true }
    
    override var displayName: String! {
        set {}
        get { viewModel.fileURL?.lastPathComponent ?? "" }
    }
    
    override func makeWindowControllers() {
        // Returns the Storyboard that contains your Document window.
        let storyboard = NSStoryboard(name: NSStoryboard.Name("Main"), bundle: nil)
        if let windowController = storyboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("Document Window Controller")) as? NSWindowController {
            
            addWindowController(windowController)
            windowController.contentViewController?.representedObject = viewModel
        }
    }
    
    override func read(from url: URL, ofType typeName: String) throws {
        
        viewModel.audioPlayer = try AVAudioPlayer(contentsOf: url)
        viewModel.audioPlayer?.prepareToPlay()
        
        let file = try AVAudioFile(forReading: url)
        file.framePosition = 0
        
        guard let aBuffer = AVAudioPCMBuffer(pcmFormat: file.processingFormat,
                                             frameCapacity: AVAudioFrameCount(file.length))
        else { throw AVError(.unknown) }
        
        try file.read(into: aBuffer)
        
        viewModel.audioBuffer = aBuffer
        viewModel.fileFormat = file.fileFormat
        viewModel.processingFormat = file.processingFormat
        viewModel.duration = Double(aBuffer.frameLength) / aBuffer.format.sampleRate
        viewModel.samples = aBuffer.compressed()
        viewModel.fileURL = url
        
        self.fileURL = nil
    }
}
