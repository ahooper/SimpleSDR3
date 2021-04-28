//
//  DemodulateAM.swift
//  SimpleSDR3
//
//  Created by Andy Hooper on 2020-09-04.
//  Copyright © 2020 Andy Hooper. All rights reserved.
//

import SimpleSDRLibrary

class DemodulateAM:DemodulateAudio {

    init<S:SourceProtocol>(source:S,
                           suppressedCarrier:Bool=false)
                    where S.Output == ComplexSamples {
        super.init("DemodulateAM")
        let sourceSampleHz = Int(source.sampleFrequency()),
            AM_SAMPLE_HZ = 100000,
            audioSampleHz = Int(audioOut.sampleFrequency()),
            AUDIO_FILTER_HZ = 5000, //TODO settable
            LOW_FILTER_HZ = 50
        let downSampleIF = UpFIRDown(source:source,
                                     AM_SAMPLE_HZ,
                                     sourceSampleHz,
                                     7, // * 10 * 2
                                     Float(AUDIO_FILTER_HZ*2) / Float(AM_SAMPLE_HZ),
                                     windowFunction:FIRKernel.blackman)
        let demodulated = suppressedCarrier
                                ? AMCostasDemodulate(source:downSampleIF,
                                                     factor: 0.5)
                                : AMEnvDemodulate(source:downSampleIF,
                                                  factor: 0.5)
//        let passKernel = FIRKernel.bandPass(filterLength: 51,
//                                            transition1Frequency: Float(LOW_FILTER_HZ),
//                                            transition2Frequency: Float(AUDIO_FILTER_HZ),
//                                            sampleFrequency: Float(audioSampleHz))
//        let downPass = UpFIRDown(source: demodulated,
//                                   audioSampleHz,
//                                   passKernel,
//                                   AM_SAMPLE_HZ)
        let downSampleAF = UpFIRDown(source:demodulated,
                                     audioSampleHz,
                                     AM_SAMPLE_HZ,
                                     15, // * 25 * 2
                                     Float(AUDIO_FILTER_HZ) / Float(audioSampleHz),
                                     windowFunction:FIRKernel.blackman) // kaiser(5.0f));
        let audioDC = DCRemove(source:downSampleAF, 64)
        let audioAGC = AutoGainControl(source:audioDC)
        audioOut.setSource(source:audioAGC)
        
        let spectrumSource = //source
                             //downSampleIF
                             //RealToComplex(source: demodulated)
                             //RealToComplex(source: downSampleAF)
                             RealToComplex(source: audioDC)
                             //RealToComplex(source: audioAGC)
        spectrum.setSource(spectrumSource)
        
        scope.setSource(audioAGC)
    }

}
