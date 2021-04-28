//
//  ScopeView.swift
//  SimpleSDR3
//
//  Created by Andy Hooper on 2021-01-04.
//  Copyright © 2021 Andy Hooper. All rights reserved.
//

import AppKit

class ScopeView: GraphView {
    
    var sampleHz: Float = 1.0 {
        didSet { buildAxes() }
    }
    var verticalScale: Float = 1.0 {
        didSet { buildAxes() }
    }
    enum TriggerType { case off, rising, falling }
    var triggerType: TriggerType = .off
    var triggerLevel: Float = 0

    override init(frame frameRect: NSRect) {
       
        super.init(frame: frameRect)
        
        commonInit()
    }
    
    /// Initialize (from storyboard or XIB, I'm guessing)
    required init?(coder: NSCoder) {

        super.init(coder:coder)
        
        commonInit()
    }

    private func commonInit() {
        axesDelegate?.annotationColour = #colorLiteral(red: 0.8, green: 0.8, blue: 0.8, alpha: 1)
        axesDelegate!.xLabel = "Time (ms)"
        axesDelegate!.yLabel = "Level"
        axesDelegate!.numXTickIntervals = 10
        axesDelegate!.numYTickIntervals = 5
    }
    
    /// (Re)Build the X axis data points to match the sample rate.
    func buildAxes() {
        let N = Int(lineLayer!.frame.width)+1
        xData = [Float](repeating: 0, count: N)
        let scale = 1000 / sampleHz // 1000 becuase axis unit is ms
        //print(className, #function, "vertical", verticalScale, "sampleHz", sampleHz, "N", N, "pixel", scale)
        for i in 0..<N {
            xData[i] = Float(i) * scale
        }
        minXValue = xData[0]
        maxXValue = xData[N-1]
        minYValue = -verticalScale; maxYValue = verticalScale  //TODO: dynamic Y range
        //print(className, #function, sampleHz, minXValue, maxXValue, minYValue, maxYValue)
        yData = [Float](repeating: Float.nan, count: N)
        calculateDataTransform()
        DispatchQueue.main.async {
            self.axesLayer?.setNeedsDisplay()
        }
    }

    /// Replace displayed sample points with new. Client drives this with a periodic timer.
    func newData(samples:[Float]) {
        //print(className, #function, samples.count)
        var t: Int
        switch triggerType {
        case .off:
            t = 0
        case .rising:
            t = samples.count
            var prev = Float.infinity
            for s in 0..<samples.count {
                if samples[s] >= triggerLevel && prev < triggerLevel {
                    t = s
                    break
                } else { prev = samples[s] }
            }
        case .falling:
            t = samples.count
            var prev = -Float.infinity
            for s in 0..<samples.count {
                if samples[s] <= triggerLevel && prev > triggerLevel {
                    t = s
                    break
                } else { prev = samples[s] }
            }
        }
        if t >= samples.count { return } // no trigger update
        let samp = samples[t..<samples.count]
        if yData.count <= samp.count {
            yData.replaceSubrange(0..<yData.count, with: samples[0..<yData.count])
        } else {
            yData.replaceSubrange(0..<samp.count, with:samp)
            yData.replaceSubrange(samp.count..<yData.count,
                                  with: repeatElement(Float.nan, count: yData.count-samp.count))
        }
       
        DispatchQueue.main.async {
            self.lineLayer?.setNeedsDisplay()
        }
    }

}
