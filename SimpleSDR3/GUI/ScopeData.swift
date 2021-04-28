//
//  ScopeData.swift
//  SimpleSDR3
//
//  Created by Andy Hooper on 2021-01-05.
//  Copyright © 2021 Andy Hooper. All rights reserved.
//

import Foundation
import SimpleSDRLibrary

public class ScopeData:Sink<RealSamples> {
    let window = ScopeWindow()
    var timer:Timer?
    let INTERVAL = TimeInterval(0.5/*seconds*/)
    var data = [Float]()

    public init<S:SourceProtocol>(source:S?) where S.Output == Input {
        super.init("ScopeData", source:source)
    }
    
    public override func setSource<S>(_ source: S) where Input == S.Output, S : SourceProtocol {
        window.showWindow(nil)
        window.window?.title = source.getName()
        super.setSource(source)
        timer?.invalidate()
        window.scopeView.sampleHz = Float(source.sampleFrequency())
        timer = Timer.scheduledTimer(withTimeInterval:INTERVAL, repeats:true) { timer in
            self.window.scopeView.newData(samples: self.data)
        }
    }
    
    public override func process(_ x:RealSamples) {
        //print(className, #function, x.count)
        data.replaceSubrange(0..<data.count, with: x[0..<x.count])
    }
}
