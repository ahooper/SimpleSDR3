//
//  ScopeWindow.swift
//  SimpleSDR3
//
//  Created by Andy Hooper on 2021-01-05.
//  Copyright © 2021 Andy Hooper. All rights reserved.
//

import Cocoa

class ScopeWindow: NSWindowController {
    
    override var windowNibName: NSNib.Name? { return "ScopeWindow" }

    override func windowDidLoad() {
        window?.delegate = self
        window?.title = "Scope"
        super.windowDidLoad()
        //Swift.print(className, window?.contentView?.perform(Selector(("_subtreeDescription"))))
        verticalScaleField.floatValue = 1.0 // non-zero
    }

    @IBOutlet weak var scopeView: ScopeView!
    
    @IBOutlet weak var verticalScaleField: NSTextField!
    
    @IBAction func verticalScaleAction(_ sender: Any) {
        //print(#function, sender, verticalScaleField.floatValue)
        scopeView.verticalScale = verticalScaleField.floatValue
    }
    
    @IBOutlet weak var triggerOffChoice: NSMenuItem!
    @IBOutlet weak var triggerRisingChoice: NSMenuItem!
    @IBOutlet weak var triggerFallingChoice: NSMenuItem!
    
    @IBAction func triggerTypeAction(_ sender: Any) {
        //print(#function, sender, triggerOffChoice.state, triggerRisingChoice.state, triggerFallingChoice.state)
        if triggerOffChoice.state == .on {
            scopeView.triggerType = .off
            triggerLevelField.isEnabled = false
        } else if triggerRisingChoice.state == .on {
            scopeView.triggerType = .rising
            triggerLevelField.isEnabled = true
        } else if triggerFallingChoice.state == .on {
            scopeView.triggerType = .falling
            triggerLevelField.isEnabled = true
        }
    }
    
    @IBOutlet weak var triggerLevelField: NSTextField!
    
    @IBAction func triggerLevelAction(_ sender: Any) {
        //print(#function, sender, triggerLevelField.floatValue)
        scopeView.triggerLevel = triggerLevelField.floatValue
    }
    
}

extension ScopeWindow: NSWindowDelegate {
    
    func windowDidResize(_ notification: Notification) {
        scopeView.buildAxes()
    }
    
}
