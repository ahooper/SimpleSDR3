//
//  GraphView.swift
//  SimpleSDR3
//
//  https://www.raywenderlich.com/411-core-graphics-tutorial-part-1-getting-started
//  https://www.raywenderlich.com/410-core-graphics-tutorial-part-2-gradients-and-contexts
//  https://www.raywenderlich.com/1101-core-graphics-on-macos-tutorial
//
//  Created by Andy Hooper on 2021-01-04.
//  Copyright © 2021 Andy Hooper. All rights reserved.
//

import AppKit

class GraphAxesDelegate: NSObject, CALayerDelegate {
    let view:GraphView
    var xLabel = "X", yLabel = "Y"
    var annotationColour = #colorLiteral(red: 0.6000000238, green: 0.6000000238, blue: 0.6000000238, alpha: 1)
    var backgroundColour = #colorLiteral(red: 0.04992193788, green: 0.1363252965, blue: 0.1958476027, alpha: 1)
    var numXTickIntervals = 10, numYTickIntervals = 5
    var tickLength = 5.0 // in display points
    var tickLabelOffset = 2.0
    var axisLineWidth = 0.5
    var labelFontSize = 10

    init(_ view: GraphView) {
        self.view = view
    }
    
    /// Draw and label the graph axes.
    func draw(_ layer: CALayer, in ctx: CGContext) {
 
        let xLabelFormatter = NumberFormatter(),
            yLabelFormatter = NumberFormatter()
        xLabelFormatter.usesSignificantDigits = true
        xLabelFormatter.minimumSignificantDigits = 3
        xLabelFormatter.maximumSignificantDigits = 5
        yLabelFormatter.usesSignificantDigits = true
        yLabelFormatter.minimumSignificantDigits = 2
        yLabelFormatter.maximumSignificantDigits = 3
        let labelFont = NSFont.labelFont(ofSize: CGFloat(labelFontSize))
        let labelTextAttributes = [
            NSAttributedString.Key.font: labelFont,
            NSAttributedString.Key.paragraphStyle: NSParagraphStyle.default,
            NSAttributedString.Key.foregroundColor: annotationColour]

        ctx.saveGState()
        ctx.translateBy(x: view.margin.left, y: view.margin.bottom)
        ctx.setStrokeColor(annotationColour.cgColor)
        ctx.beginPath()
        ctx.setLineWidth(CGFloat(axisLineWidth))

        let origin = CGPoint(x: CGFloat(view.minXValue),
                             y: CGFloat(view.minYValue)).applying(view.dataTransform),
            limit =  CGPoint(x: CGFloat(view.maxXValue),
                             y: CGFloat(view.maxYValue)).applying(view.dataTransform)
        //print("GraphAxesDelegate draw",layer.bounds,origin.applying(ctx.ctm),limit.applying(ctx.ctm))
        //print(view.dataTransform)
        //print("GraphAxesDelegate start", origin.x, limit.y)
        assert(!origin.x.isNaN)
        assert(!limit.y.isNaN)
        ctx.move(to: CGPoint(x: origin.x, y: limit.y))
        ctx.addLine(to: origin)
        ctx.addLine(to: CGPoint(x: limit.x, y: origin.y))
        
        let xTickInterval = Float(view.maxXValue - view.minXValue) / Float(numXTickIntervals),
            yTickInterval = Float(view.maxYValue - view.minYValue) / Float(numYTickIntervals)
        for i in 0...numXTickIntervals {
            let xv = xTickInterval * Float(i) + Float(view.minXValue),
                ap = CGPoint(x:CGFloat(xv),
                             y:CGFloat(view.minYValue) ).applying(view.dataTransform)
            //print("GraphAxesDelegate X",xTickInterval,view.minXValue,i,xv)
            //print("GraphAxesDelegate x tick", ap.x, ap.y-CGFloat(tickLength))
            assert(!ap.x.isNaN)
            assert(!ap.y.isNaN)
            ctx.move(to: CGPoint(x: ap.x, y: ap.y-CGFloat(tickLength)))
            ctx.addLine(to: CGPoint(x: ap.x, y: limit.y))
            drawLabel(text: xLabelFormatter.string(from: NSNumber(value: xv))!,
                      attributes: labelTextAttributes,
                      x: ap.x,
                      y: ap.y-CGFloat(tickLength+tickLabelOffset),
                      widthFactor: -0.5,
                      heightFactor: -1.0,
                      context: ctx)
        }
        drawLabel(text: xLabel,
                  attributes: labelTextAttributes,
                  x: (limit.x-origin.x)/2,
                  y: origin.y-CGFloat(tickLength+tickLabelOffset*2),
                  widthFactor: -0.5,
                  heightFactor: -2.0,
                  context: ctx)

        for i in 0...numYTickIntervals {
            let yv = yTickInterval * Float(i) + Float(view.minYValue),
                ap = CGPoint(x:CGFloat(view.minXValue),
                             y:CGFloat(yv) ).applying(view.dataTransform)
            //print("GraphAxesDelegate y tick", ap.x-CGFloat(tickLength), ap.y)
            assert(!ap.x.isNaN)
            assert(!ap.y.isNaN)
            ctx.move(to: CGPoint(x: ap.x-CGFloat(tickLength), y: ap.y))
            ctx.addLine(to: CGPoint(x: limit.x, y: ap.y))
            ctx.saveGState()
            ctx.rotate(by: CGFloat.pi/2.0)
            drawLabel(text: yLabelFormatter.string(from: NSNumber(value: yv))!,
                      attributes: labelTextAttributes,
                      x: ap.y,
                      y: -ap.x+CGFloat(tickLength+tickLabelOffset),
                      // coordinates are swapped, as the point will be rotated
                      widthFactor: -0.5,
                      heightFactor: 0.0,
                      context: ctx)
            ctx.restoreGState()
        }
        ctx.saveGState()
        ctx.rotate(by: CGFloat.pi/2.0)
        drawLabel(text: yLabel,
                  attributes: labelTextAttributes,
                  x: (limit.y-origin.y)/2,
                  y: -origin.x+CGFloat(tickLength+tickLabelOffset*2),
                  // coordinates are swapped, as the point will be rotated
                  widthFactor: -0.5,
                  heightFactor: 1.0,
                  context: ctx)
        ctx.restoreGState()

        ctx.strokePath()
        ctx.restoreGState()

    }
    
    /// Draw a text label on the axes.
    func drawLabel(text: String,
                   attributes: [NSAttributedString.Key : NSObject],
                   x: CGFloat,
                   y: CGFloat,
                   widthFactor: CGFloat,
                   heightFactor: CGFloat,
                   context: CGContext) {
        let attrText = NSAttributedString(string: text,
                                          attributes: attributes)
        let textSize = attrText.size()
        let textLine = CTLineCreateWithAttributedString(attrText)
        context.textPosition = CGPoint(x: x + textSize.width * widthFactor,
                                       y: y + textSize.height * heightFactor)
        CTLineDraw(textLine, context)
    }
}

class GraphLineDelegate: NSObject, CALayerDelegate {
    let view: GraphView
    var lineColour = #colorLiteral(red: 0.8964041096, green: 0.9716730004, blue: 1, alpha: 1)
    var lineWidth = 1.0

    init(_ view: GraphView) {
        self.view = view
    }
    
    /// Draw the graph
    func draw(_ layer: CALayer, in ctx: CGContext) {
        if view.xData.count > 1 {
            ctx.saveGState()
            ctx.concatenate(view.dataTransform)
            let xd = view.xData, yd = view.yData
            var move = true
            for i in 0..<yd.count {
                if yd[i].isNaN { /*missing point*/ move = true; continue }
                let p = CGPoint(x:CGFloat(xd[i]),
                                y:CGFloat(yd[i]))
                if move {
                    ctx.move(to: p)
                    move = false
                } else {
                    ctx.addLine(to: p)
                }
            }
            ctx.restoreGState()
            // set line width after data transform has been removed
            // https://stackoverflow.com/a/13339008/302852
            ctx.setStrokeColor(lineColour.cgColor)
            ctx.setLineWidth(CGFloat(lineWidth))
            ctx.strokePath()
        }
    }
}

class GraphMetalDelegate: NSObject, CALayerDelegate {
    let view: GraphView
    let commandQueue: MTLCommandQueue!
    let pipelineState: MTLRenderPipelineState!
    var displayLink: CVDisplayLink?

    init(_ view: GraphView) {
        self.view = view
        
        // Make library with shaders
        let library = view.metalDevice.makeDefaultLibrary()!
        //print("GraphMetalDelegate library",library.functionNames)
        let vertexFunction = library.makeFunction(name: "vertexShader")!
        let fragmentFunction = library.makeFunction(name: "fragmentShader")!
        
        // Set up a descriptor for creating a pipeline state object
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.label = "GraphMetalPipeline"
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        //pipelineDescriptor.vertexDescriptor = MTKMetalVertexDescriptorFromModelIO(mdlMesh.vertexDescriptor)
        pipelineDescriptor.colorAttachments[0].pixelFormat = view.metalLayer!.pixelFormat
        do {
            pipelineState = try view.metalDevice.makeRenderPipelineState(descriptor: pipelineDescriptor)
        } catch let error {
            fatalError(error.localizedDescription)
        }

        commandQueue = view.metalDevice.makeCommandQueue()!

        let displayLinkOutputCallback: CVDisplayLinkOutputCallback = {(displayLink: CVDisplayLink, inNow: UnsafePointer<CVTimeStamp>, inOutputTime: UnsafePointer<CVTimeStamp>, flagsIn: CVOptionFlags, flagsOut: UnsafeMutablePointer<CVOptionFlags>, displayLinkContext: UnsafeMutableRawPointer?) -> CVReturn in
            let view = Unmanaged<GraphMetalDelegate>.fromOpaque(displayLinkContext!).takeUnretainedValue()
            DispatchQueue.main.async {
                view.drawView()
            }
            return kCVReturnSuccess
        }
        CVDisplayLinkCreateWithActiveCGDisplays(&displayLink)
        super.init()
        CVDisplayLinkSetOutputCallback(displayLink!,
                                       displayLinkOutputCallback,
                                       UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque()))
        CVDisplayLinkStart(displayLink!)
    }
    
    let triangleVertices: [AAPLVertex] = [
        // 2D positions,    RGBA colors
        AAPLVertex(position:vector_float2(  250,  -250 ), color:vector_float4( 1, 0, 0, 1 )),
        AAPLVertex(position:vector_float2( -250,  -250 ), color:vector_float4( 0, 1, 0, 1 )),
        AAPLVertex(position:vector_float2(    0,   250 ), color:vector_float4( 0, 0, 1, 1 )),
        AAPLVertex(position:vector_float2(  250,  -250 ), color:vector_float4( 1, 0, 0, 1 )) ]
    func drawView() {
        //print("GraphMetalDelegate drawView")
        
        // Create a new command buffer for each render pass to the current drawable
        let commandBuffer = commandQueue.makeCommandBuffer()!
        commandBuffer.label = "GraphMetalCommand"
        guard let drawable = view.metalLayer!.nextDrawable()
        else {
            print("GraphMetalDelegate drawView no Drawable")
            return
        }
        let renderPassDescriptor = MTLRenderPassDescriptor()
        renderPassDescriptor.colorAttachments[0].texture = drawable.texture
        renderPassDescriptor.colorAttachments[0].loadAction = .clear
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColor(red:0.0, green:0.0, blue:0.0, alpha:0.0)
        guard let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)
        else {
            print("GraphMetalDelegate drawView no RenderCommandEncoder")
            return
        }
        renderEncoder.label = "GraphMetalRenderEncoder"

        // Set the region of the drawable to draw into.
        renderEncoder.setViewport(MTLViewport(originX:0.0, originY:0.0,
                                              width:Double(view.frame.size.width),
                                              height:Double(view.frame.size.height),
                                              znear:0.0, zfar:1.0))
        renderEncoder.setRenderPipelineState(pipelineState)
        
        // Set data for the vertex functions.
        let vertices = triangleVertices.withUnsafeBufferPointer { tVert in
            // metalView.device instead of device so unfinished self is not captured in closure
            view.metalDevice!.makeBuffer(bytes: tVert.baseAddress!,
                                         length: MemoryLayout<AAPLVertex>.stride * tVert.count,
                                         options: .storageModeShared)
        }
        renderEncoder.setVertexBuffer(vertices,
                                      offset: 0,
                                      index: Int(AAPLVertexInputIndexVertices.rawValue))
//        renderEncoder.setVertexBytes(triangleVertices,
//                                     length:MemoryLayout<AAPLVertex>.stride*triangleVertices.count,
//                                     index:Int(AAPLVertexInputIndexVertices.rawValue))
        var viewportSize = vector_uint2(UInt32(view.frame.size.width),
                                        UInt32(view.frame.size.height))
        renderEncoder.setVertexBytes(&viewportSize,
                                     length:MemoryLayout<vector_uint2>.size,
                                     index:Int(AAPLVertexInputIndexViewportSize.rawValue))
        
        // Draw the lines between the vertices.
        renderEncoder.drawPrimitives(type:.lineStrip,
                                     vertexStart:0,
                                     vertexCount: triangleVertices.count)
        renderEncoder.endEncoding()
        
        // Schedule a present
        commandBuffer.present(drawable)
        
        // Finalize rendering here & push the command buffer to the GPU.
        commandBuffer.commit()
    }
}

class GraphView: NSView, CALayerDelegate {
    var xData = [Float](), yData = [Float]()
    var minXValue = Float(0.0), maxXValue = Float(1.0), minYValue = Float(0.0), maxYValue = Float(1.0)
    var margin = NSEdgeInsets(top:10, left:40, bottom:40, right:10)

    var dataTransform = CGAffineTransform.identity
    var dataInverse = CGAffineTransform.identity

    var axesLayer: CALayer?
    var lineLayer: CALayer?
    var metalLayer: CAMetalLayer?
    var axesDelegate: GraphAxesDelegate?
    var lineDelegate: GraphLineDelegate?
    var metalDelegate: GraphMetalDelegate?
    
    var metalDevice: MTLDevice!

    override init(frame frameRect: NSRect) {
       
        super.init(frame: frameRect)
        
        commonInit()
    }
    
    /// Initialize from storyboard or XIB
    required init?(coder: NSCoder) {

        super.init(coder:coder)
        
        commonInit()
    }
    
    private func commonInit() {
        layer = CALayer(); wantsLayer = true // change the View to a "layer host"
        // https://developer.apple.com/documentation/appkit/nsview/1483695-wantslayer#discussion
        // "To create a layer-hosting view, you must set the layer property first and then set this property to true. The order in which you set the values of these properties is crucial."
        layer!.backgroundColor = #colorLiteral(red: 0.05882352963, green: 0.180392161, blue: 0.2470588237, alpha: 1)
        layer!.name = "base"
        layer!.anchorPoint = CGPoint.zero
        layer!.delegate = self

        axesLayer = CALayer()
        axesLayer!.name = "axes"
        axesDelegate = GraphAxesDelegate(self)
        axesLayer!.delegate = axesDelegate
        layer!.addSublayer(axesLayer!)
        
        lineLayer = CALayer()
        lineLayer!.name = "graph"
        lineDelegate = GraphLineDelegate(self)
        lineLayer!.delegate = lineDelegate
        axesLayer!.addSublayer(lineLayer!)
        
        metalDevice = MTLCreateSystemDefaultDevice()
        guard metalDevice != nil else {
            fatalError("Metal is not supported on this device")
        }
        metalLayer = CAMetalLayer()
        metalLayer!.name = "GraphMetal"
        metalLayer!.device = metalDevice
        metalLayer!.pixelFormat = .bgra8Unorm
        metalLayer!.framebufferOnly = true
        metalDelegate = GraphMetalDelegate(self)
        metalLayer!.delegate = metalDelegate
              
        layoutSublayers(frame: layer!.frame)

        // https://stackoverflow.com/q/43456762
        let trackingRect = CGRect(x:5, y:5, width:100, height:16)
        trackingText = NSTextField(frame:trackingRect)
        trackingText!.isEditable = false
        trackingText!.isBordered = false
        trackingText!.isBezeled = false
        trackingText!.drawsBackground = false
        trackingText!.alignment = .center
        trackingText!.usesSingleLineMode = true
        let trackingController = NSViewController()
        trackingController.view = NSView(frame:CGRect(x:0, y:0,
                                                      width:trackingRect.width+trackingRect.minX*2,
                                                      height:trackingRect.height+trackingRect.minY*2))
        trackingController.view.addSubview(trackingText!)
        trackingPopover = NSPopover()
        trackingPopover!.contentViewController = trackingController
        trackingPopover!.contentSize = trackingController.view.frame.size
        trackingPopover!.behavior = .applicationDefined
        trackingPopover!.animates = false
        //Swift.print(trackingController.view.perform(Selector(("_subtreeDescription"))))
        
        updateTrackingAreas()
    }
    
    var graphTracking: NSTrackingArea?
    var trackingPopover: NSPopover?
    var trackingText: NSTextField?
    
    func layoutSublayers(frame: CGRect) {
        // https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/CoreAnimation_guide/BuildingaLayerHierarchy/BuildingaLayerHierarchy.html#//apple_ref/doc/uid/TP40004514-CH6-SW5
        // "Important: Always use integral numbers for the width and height of your layer."

        let axesHeight = frame.height,
            graphX = frame.minX + margin.left,
            graphWidth = frame.maxX - graphX - margin.right
        axesLayer!.frame = CGRect(x: frame.minX, y: frame.minY,
                                  width: frame.width, height: axesHeight)
        lineLayer!.frame = CGRect(x: margin.left, y: margin.bottom, /*relative to axesLayer*/
                                   width: graphWidth, height: axesHeight-margin.bottom-margin.top)
        metalLayer!.frame = lineLayer!.frame

        calculateDataTransform()

        axesLayer!.setNeedsDisplay()
        lineLayer!.setNeedsDisplay()
        metalLayer!.setNeedsDisplay()
    }

    func calculateDataTransform() {
        //print(#function, window?.title, maxXValue, minXValue, maxYValue, minYValue)
        assert(maxXValue > minXValue)
        assert(maxYValue > minYValue)
        dataTransform = CGAffineTransform.identity
                                .scaledBy(x: lineLayer!.bounds.width / CGFloat(maxXValue - minXValue),
                                          y: lineLayer!.bounds.height / CGFloat(maxYValue - minYValue) )
                                .translatedBy(x: CGFloat(-minXValue),
                                              y: CGFloat(-minYValue) )
        dataInverse = dataTransform.inverted()
    }

    // Cursor location tracking
       
    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if graphTracking != nil {
            removeTrackingArea(graphTracking!)
            graphTracking = nil
        }
        let graphRect = layer!.convert(lineLayer!.bounds, from: lineLayer)
        //print("updateTrackingAreas",graphRect)
        graphTracking = NSTrackingArea(rect: graphRect,
                                       options: [.mouseEnteredAndExited, .mouseMoved, /*.cursorUpdate,*/
                                                 .activeInActiveApp],
                                       owner: self,
                                       userInfo: [:])
        addTrackingArea(graphTracking!)
    }
    
    override func mouseEntered(with event: NSEvent) {
        NSCursor.crosshair.set()
    }
    
    func viewLocationInData(_ viewLocation:NSPoint)->NSPoint? {
        if let graphLocation = layer?.convert(viewLocation, to: lineLayer),
           lineLayer?.bounds.contains(graphLocation) ?? false {
            return NSPoint(x: graphLocation.applying(dataInverse).x,
                           y: graphLocation.applying(dataInverse).y)
        }
        return nil
    }

    override func mouseMoved(with event: NSEvent) {
        let viewLocation = convert(event.locationInWindow, from:nil as NSView?)
        if let dataLocation = viewLocationInData(viewLocation) {
            let text = String(format: (dataLocation.x > 1e3) ? "%.0f:%.1f"
                                    : "%.2f:%.1f",
                              dataLocation.x, dataLocation.y)
            trackingText?.stringValue = text
            trackingPopover?.show(relativeTo:NSRect(origin:viewLocation,
                                                    size:CGSize(width:1, height:1)),
                                  of:self,
                                  preferredEdge:NSRectEdge.minY)
        } else {
            trackingPopover?.close()
        }
    }
    
    override func mouseExited(with event: NSEvent) {
        trackingPopover?.close()
        NSCursor.arrow.set()
    }
    
    // Resizing
    
    override func viewDidEndLiveResize() {
        layoutSublayers(frame: layer!.frame)
        updateTrackingAreas()
        needsDisplay = true
        super.viewDidEndLiveResize()
    }
    
}
