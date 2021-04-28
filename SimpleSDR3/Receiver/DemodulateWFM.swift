//
//  DemodulateWFM.swift
//  SimpleSDR3
//
//  https://en.wikipedia.org/wiki/FM_broadcasting#Technology
//  https://www.law.cornell.edu/cfr/text/47/73.310
//
//  Created by Andy Hooper on 2020-02-26.
//  Copyright © 2020 Andy Hooper. All rights reserved.
//

import SimpleSDRLibrary

class DemodulateWFM:DemodulateAudio {
    static let FREQUENCY_DEVIATION = 75000, //TODO configurable at init
               DEEMPHASIS_TIME = Float(75e-6)
    var pilotDetect: AutoGainControl<RealSamples>?

    init<S:SourceProtocol>(source:S)
                    where S.Output == ComplexSamples {
        super.init("DemodulateWFM")
        let sourceSampleHz = Int(source.sampleFrequency())
        let WFM_SAMPLE_HZ = 200000,
            WFM_FILTER_HZ = DemodulateWFM.FREQUENCY_DEVIATION
        let downSampleIF = UpFIRDown(source:source,
                                     WFM_SAMPLE_HZ,
                                     sourceSampleHz,
                                     15, // * 10 * 2
                                     Float(WFM_FILTER_HZ) / Float(WFM_SAMPLE_HZ),
                                     windowFunction:FIRKernel.blackman) // kaiser(5.0f));
        let demodulated = FMDemodulate(source:downSampleIF,
                                        modulationFactor: 0.5) //(WFM_FREQUENCY_DEVIATION / WFM_SAMPLE_HZ));
        let PILOT_CENTRE_HZ = Float(19000)
        let pilotPeak = FIRKernel.peak(filterSemiLength: 29,
                                       normalizedPeakFrequency: Float(PILOT_CENTRE_HZ) / Float(WFM_SAMPLE_HZ),
                                       stopBandAttenuation: 60)
        //FIRKernel.plotFrequencyResponse(pilotPeak, title: "FM Pilot Filter")
        let pilotFilter = FIRFilter(source:demodulated,
                                    pilotPeak)
//        let pilotFilter = Goertzel(source:demodulated, targetFrequencyHz:PILOT_CENTRE_HZ, Nfft: 200)
        pilotDetect = AutoGainControl(source:pilotFilter)
        let audioSampleHz = Int(audioOut.sampleFrequency()),
            AUDIO_FILTER_HZ = 15000
        let downSampleAF = UpFIRDown(source:demodulated,
                                     audioSampleHz,
                                     WFM_SAMPLE_HZ,
                                     15, // * 25 * 2
                                     Float(AUDIO_FILTER_HZ) / Float(audioSampleHz),
                                     windowFunction:FIRKernel.blackman) // kaiser(5.0f));
        let deemphasis = FMDeemphasis(source: downSampleAF,
                                      tau: DemodulateWFM.DEEMPHASIS_TIME)
        let audioDC = DCRemove(source:deemphasis, 64)
        let audioAGC = AutoGainControl(source:audioDC)
        audioOut.setSource(source:audioAGC)
        
        //let spectrumSource = downSampleIF
        //let spectrumSource = RealToComplex(source: demodulated)
        let spectrumSource = RealToComplex(source:downSampleAF)
        //let spectrumSource = RealToComplex(source: audioAGC)
        spectrum.setSource(spectrumSource)
        
        scope.setSource(audioAGC)
    }

}
