//
//  ReceiveSDR.swift
//  SimpleSDR3
//
//  Created by Andy Hooper on 2020-02-26.
//  Copyright © 2020 Andy Hooper. All rights reserved.
//

import SimpleSDRLibrary

class ReceiveSDR:ReceiveThread {
    let tuner = SDRplay()
    let demodSwitch:DemodulatorSwitch
    let tunerSpectrum:SpectrumData
    var pilotDetect:AutoGainControl<RealSamples>?
    
    override init() {
        tuner.setOption(SDRplay.OptRFNotch, SDRplay.Opt_Disable)
        tunerSpectrum = SpectrumData("ReceiveSDR SpectrumData", source:tuner, asThread:true, log2Size:10)
        demodSwitch = DemodulatorSwitch()
        demodSwitch.setSource(tuner)
        super.init()
        setDemodulator(.None)
    }
    
    var deviceDescription: String {
        return tuner.deviceDescription
    }
    
    func printTimes() {
        //tuner.printTimes()
        //audio.fillTime.printAccumulated(reset:true)
        //if self.startTime != DispatchTime.distantFuture {
        //    let t = Float(DispatchTime.now().uptimeNanoseconds - self.startTime.uptimeNanoseconds) / 1e9
        //    print("Tuner rate", Float(tuner.sampleCount) / t)
        //    print("Audio rate", Float(audio.sampleCount) / t)
        //}
        if let pilot = pilotDetect { print("Pilot", pilot.getSignalLevel()) }
    }
    
    func startReceive() {
        demodSwitch.currentDemod?.audioOut.resume()
        tuner.startReceive()
    }
    
    func stopReceive() {
        //TODO fix noise on stopping
        demodSwitch.currentDemod?.audioOut.stop()
        tuner.stopReceive()
        var spectrumData = [Float](repeating:0, count:tunerSpectrum.N)
        tunerSpectrum.getdBandClear(&spectrumData)
    }
    
    enum Demodulator {
        case None
        case WFM
        case AM
        case DSBSC
    }
    var demod = Demodulator.None

    func setDemodulator(_ demod:Demodulator) {
        if self.demod == demod { return }
        switch demod {
        case .None:
            demodSwitch.sink = nil
            demodSwitch.set(DemodulateNone(source:demodSwitch))
            pilotDetect = nil
        case .WFM:
            demodSwitch.sink = nil
            let demodWFM: DemodulateWFM = DemodulateWFM(source:demodSwitch)
            demodSwitch.set(demodWFM)
            pilotDetect = demodWFM.pilotDetect
        case .AM:
            demodSwitch.sink = nil
            demodSwitch.set(DemodulateAM(source:demodSwitch))
            pilotDetect = nil
        case .DSBSC:
            demodSwitch.sink = nil
            demodSwitch.set(DemodulateAM(source:demodSwitch,
                                         suppressedCarrier:true))
            pilotDetect = nil
        }
        self.demod = demod
    }

    override func mainLoop() {

        tuner.receiveLoop()

    }
}
