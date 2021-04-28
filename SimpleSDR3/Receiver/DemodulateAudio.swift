//
//  DemodulateAudio.swift
//  SimpleSDR3
//
//  Created by Andy Hooper on 2020-02-26.
//  Copyright © 2020 Andy Hooper. All rights reserved.
//

import SimpleSDRLibrary

class DemodulateAudio:Sink<ComplexSamples> {
    let audioOut = AudioOutput()
    let spectrum = SpectrumData("Demodulated SpectrumData",
                                source:SourceBox<ComplexSamples>.NilComplex(),
                                asThread:true, log2Size:10)
    let scope = ScopeData(source:SourceBox<RealSamples>.NilReal())
}
