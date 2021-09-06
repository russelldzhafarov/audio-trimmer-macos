//
//  Document.swift
//  audio-trimmer-macos
//
//  Created by russell.dzhafarov@gmail.com on 06.09.2021.
//

import Cocoa

class Document: NSDocument {
    
    override func makeWindowControllers() {
        // Returns the Storyboard that contains your Document window.
        let storyboard = NSStoryboard(name: NSStoryboard.Name("Main"), bundle: nil)
        let windowController = storyboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("Document Window Controller")) as! NSWindowController
        
        (windowController.contentViewController as? TrimmerViewController)?.fileURL = fileURL
        
        self.addWindowController(windowController)
    }
    override func read(from url: URL, ofType typeName: String) throws {
        self.fileURL = url
    }
}
