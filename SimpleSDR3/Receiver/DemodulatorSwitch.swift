//
//  DemodulatorSwitch.swift
//  SimpleSDR3
//
//  Created by Andy Hooper on 2020-11-24.
//  Copyright © 2020 Andy Hooper. All rights reserved.
//

import Foundation
import SimpleSDRLibrary

public class DemodulatorSwitch:Sink<ComplexSamples>, SourceProtocol {
    public typealias Output = ComplexSamples
    
    var sink: SinkBox<Output>?
    var currentDemod:DemodulateAudio?

    public init() {
        super.init("DemodulatorSwitch")
    }
    func set(_ demod:DemodulateAudio) {
        currentDemod = demod
    }
    public func addSink<S>(_ sink: S, asThread: Bool)
                where S : SinkProtocol, Output == S.Input {
        if self.sink == nil {
            self.sink = SinkBoxHelper(sink)
        } else {
            fatalError("DemodulatorSwitch addSink cannot be called twice")
        }
    }
    public override func process(_ input:Input) {
        //print("DemodulatorSwitch process", input.count)
        if let s = sink {
            return s.process(input)
        } else {
        }
    }
    /// Get the sampling frequency this stage is processing.
    public func sampleFrequency()-> Double {
        if let source = source { return source.sampleFrequency() }
        else { return Double.nan }
    }
    /// Read the next block from the source. Return nil if exiting.
    public func read()-> Output? {
        return source!.read()
    }
    public func hasFinished()-> Bool {
        return source!.hasFinished()
    }
    public func getName()-> String {
        return "DemodulatorSwitch"
    }
}
