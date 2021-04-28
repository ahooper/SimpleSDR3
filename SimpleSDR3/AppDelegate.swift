//
//  AppDelegate.swift
//  SimpleSDR3
//
//  Created by Andy Hooper on 2019-12-15.
//  Copyright © 2019 Andy Hooper. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }

    @IBAction func crashDumpAction(_ sender: Any) {
        fatalError("Crash Dump")
    }
}

