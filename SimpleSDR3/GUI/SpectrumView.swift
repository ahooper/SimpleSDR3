//
//  SpectrumView.swift
//  SimpleSDR
//
//  Created by Andy Hooper on 2019-09-28.
//  Copyright © 2019 Andy Hooper. All rights reserved.
//

import AppKit
import SpriteKit
import class SimpleSDRLibrary.SpectrumData

class SpectrumView: GraphView {
    
    var viewCentreHz = 0.0
    var viewSampleHz = 0.0
    
    var rebuildAxis = true

    let frequencyScale = 1000.0

    let graphProportion = CGFloat(0.25)
    var waterfallView: SKView?
    var waterfall: WaterfallScene?
    
    override init(frame frameRect: NSRect) {
       
        super.init(frame: frameRect)
        
        // not expecting to be called
        print("SpectrumView init(frameRect:)")
    }
    
    /// Initialize (from storyboard or XIB, I'm guessing)
    required init?(coder: NSCoder) {

        super.init(coder:coder)
        
        axesDelegate!.xLabel = "Frequency (kHz)"
        axesDelegate!.yLabel = "Level (dB)"
        axesDelegate!.numXTickIntervals = 10
        axesDelegate!.numYTickIntervals = 5

        waterfallView = SKView()
        waterfallView!.showsFPS = true
        waterfallView!.showsNodeCount = true
        //waterfallView!.showsDrawCount = true
        //waterfallView!.showsQuadCount = true
        waterfallView!.ignoresSiblingOrder = true
        waterfallView!.allowsTransparency = true
        addSubview(waterfallView!)
        waterfall = WaterfallScene(size: frame.size/*temporary size*/)
        waterfall!.scaleMode = .resizeFill
        waterfall!.anchorPoint = CGPoint.zero
        waterfall!.backgroundColor = NSColor.clear
        waterfall!.setPalette(Palettes.viridis, alpha: 1.0)
        
        layoutSublayers(frame: layer!.frame)
        
        waterfallView!.presentScene(waterfall) // present empty scene to show background

    }
    
    override func layoutSublayers(frame: CGRect) {
        // https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/CoreAnimation_guide/BuildingaLayerHierarchy/BuildingaLayerHierarchy.html#//apple_ref/doc/uid/TP40004514-CH6-SW5
        // "Important: Always use integral numbers for the width and height of your layer."
        
        let (graphFrame, waterfallFrame) =
                        frame.divided(atDistance: CGFloat(Int(frame.height * graphProportion)),
                                      from: .maxYEdge)
        
        super.layoutSublayers(frame: graphFrame)
        guard waterfallView != nil else { return } // first call from super.init()
        
        let graphArea = lineLayer!.frame
        waterfallView!.frame = CGRect(x: graphArea.minX, y: waterfallFrame.minY,
                                      width: graphArea.width, height: waterfallFrame.height)

        rebuildAxis = true
    }
    
    /// (Re)Build the X axis data points to match the receiver frequency settings and FFT size.
    func buildXData(_ N: Int) {
        rebuildAxis = false
        assert(N&1 == 0) // i.e. N is even
        xData = [Float](repeating: 0, count: N)
        let Nover2 = Float(N) / Float(2.0)
        let scale = Float(viewSampleHz) / Float(N)
        for i in 0..<N {
            xData[i] = ((Float(i) - Nover2) * scale + Float(viewCentreHz)) / Float(frequencyScale)
        }
        minXValue = xData[0]
        maxXValue = ((Float(N) - Nover2) * scale + Float(viewCentreHz)) / Float(frequencyScale)
                        // axis has one more point
        print("SpectrumView XData",viewCentreHz,viewSampleHz,Nover2,scale,minXValue,xData[N/2],maxXValue)
        minYValue = -100; maxYValue = 0  //TODO: dynamic Y range
        calculateDataTransform()
        DispatchQueue.main.async {
            self.axesLayer?.setNeedsDisplay()
        }
    }

    /// Replace displayed spectrum data with new. Client drives this with a periodic timer.
    func newData(source:SpectrumData) {
        let N = Int(source.N)
        if yData.count != N {
            yData = [Float](repeating: Float.nan, count: N)
        }
        if rebuildAxis
            || viewSampleHz != source.sampleFrequency()
            || viewCentreHz != source.centreHz
            || xData.count != N {
            viewSampleHz = source.sampleFrequency()
            viewCentreHz = source.centreHz
            buildXData(N)
        }
        source.getdBandClear(&yData)
        assert(yData[N-1] != Float.nan)
        
        waterfall!.addLine(data:yData, minValue:minYValue, maxValue:maxYValue)

        DispatchQueue.main.async {
            self.lineLayer?.setNeedsDisplay()
            self.waterfallView!.presentScene(self.waterfall)
        }
    }
    
    override func mouseUp(with event: NSEvent) {
        let viewLocation = convert(event.locationInWindow, from:nil as NSView?)
        if let dataLocation = viewLocationInData(viewLocation) {
            print(className, #function, dataLocation)
            NotificationCenter.default.post(name: SpectrumView.ClickedPoint,
                                            object: self,
                                            userInfo: [
                                                "coordinates": dataLocation,
                                                "frequency":dataLocation.x])
        }
    }

    static let ClickedPoint = NSNotification.Name("ClickedPoint")
}
