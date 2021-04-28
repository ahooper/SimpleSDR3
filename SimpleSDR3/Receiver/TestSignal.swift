//
//  TestSignal.swift
//  SimpleSDR3
//
//  Created by Andy Hooper on 2020-01-26.
//  Copyright © 2020 Andy Hooper. All rights reserved.
//

import SimpleSDRLibrary
import class Foundation.Thread

class TestSignal:ReceiveThread {
    let tone:Oscillator<RealSamples>
    let spectrum:SpectrumData

    override init() {
        let SAMPLE_HZ = 2e6
        let TONE_HZ = 440e0
        let CARRIER_HZ = SAMPLE_HZ/10
        tone = Oscillator<RealSamples>(signalHz:TONE_HZ, sampleHz:SAMPLE_HZ, level:0.2)
    #if !true
        let MODULATION_WIDTH = Double(DemodulateWFM.FREQUENCY_DEVIATION)
        let modulated = FMTestBaseband(source:tone,
                                       modulationFactor:Float(MODULATION_WIDTH/SAMPLE_HZ))
        let demodulate = DemodulateWFM(source:modulated)
        spectrum = demodulate.spectrum
    #elseif !true
        let modulated = AMModulate(source: tone,
                                   factor: 0.5,
                                   carrierHz: CARRIER_HZ,
                                   suppressedCarrier: false)
        let demodulate = DemodulateAM(source:modulated,
                                      suppressedCarrier: false)
        spectrum = demodulate.spectrum
    #elseif true
        let modulated = AMModulate(source: tone,
                                   factor: 0.5,
                                   carrierHz: CARRIER_HZ,
                                   suppressedCarrier: true)
        let demodulate = DemodulateAM(source:modulated,
                                      suppressedCarrier: true)
        spectrum = demodulate.spectrum
    #endif
        super.init()
    }

    //public let processTime = TimeReport(subjectName:"TestTone process", highnS:10_700_000)
    // audio buffer refresh interval: 512 samples in buffer / 48000 samples/second = ~0.0106666667 seconds

    override func mainLoop() {

        while !Thread.current.isCancelled {
            //processTime.start()
            tone.generate()
            //processTime.stop()
        }
        //print("TestSignal", "main exit")

    }
}
