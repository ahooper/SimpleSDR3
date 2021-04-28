//
//  DemodulateNone.swift
//  SimpleSDR3
//
//  Created by Andy Hooper on 2020-09-04.
//  Copyright © 2020 Andy Hooper. All rights reserved.
//

import SimpleSDRLibrary

class DemodulateNone:DemodulateAudio {

   init<S:SourceProtocol>(source:S)
                   where S.Output == ComplexSamples {
        super.init("DemodulateNone")
        audioOut.zero()
    }
}
