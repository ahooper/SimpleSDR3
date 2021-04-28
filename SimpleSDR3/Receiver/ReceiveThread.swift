//
//  ReceiveThread.swift
//  SimpleSDR3
//
//  Created by Andy Hooper on 2020-02-02.
//  Copyright © 2020 Andy Hooper. All rights reserved.
//

import class Foundation.Thread
import class Foundation.ProcessInfo
import protocol Foundation.NSObjectProtocol

class ReceiveThread:Thread {
   
    func mainLoop() {
        fatalError("mainLoop() is not implemented")
    }
    
    var activityToken: NSObjectProtocol?

    override func main() {
        self.name = "ReceiveThread"
        self.qualityOfService = .userInteractive
        // https://lapcatsoftware.com/articles/prevent-app-nap.html
        // http://arsenkin.com/Disable-app-nap.html
        // https://developer.apple.com/library/archive/documentation/Performance/Conceptual/power_efficiency_guidelines_osx/PrioritizeWorkAtTheAppLevel.html
        activityToken = ProcessInfo.processInfo.beginActivity(
                                options: [.userInitiated,.latencyCritical],
                                reason:"Real time signal")

        mainLoop()
        
        ProcessInfo.processInfo.endActivity(activityToken!)

    }
}
