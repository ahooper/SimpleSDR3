//
//  ViewController.swift
//  SimpleSDR3
//
//  Created by Andy Hooper on 2019-12-15.
//  Copyright © 2019 Andy Hooper. All rights reserved.
//

import Cocoa

import SimpleSDRLibrary

class ViewController: NSViewController {
    
    @IBOutlet weak var frequencyEntry: NSTextField!
    @IBOutlet weak var antennaSelect: NSPopUpButton!
    @IBOutlet weak var demodulatorSelect: NSPopUpButton!
    @IBOutlet weak var startStopButton: NSButton!
    @IBOutlet weak var spectrumView: SpectrumView!
    @IBOutlet weak var spectrumMenu: NSMenuItem!
    
    let SPECTRUM_INTERVAL = TimeInterval(0.1/*seconds*/) //TODO configurable
    var spectrumTimer:Timer? = nil
    var receive:ReceiveSDR?
    var windowTitle:String = "SimpleSDR3"
    
    fileprivate func startSDR() {
        receive = ReceiveSDR()
        windowTitle = receive?.deviceDescription ?? "No tuner description"
        receive!.start()
        Timer.scheduledTimer(withTimeInterval:5/*seconds*/, repeats:true) { timer in
            self.receive?.printTimes()
        }
    }
    
    fileprivate func startSpectrum(_ spec:SpectrumData?) {
        print(#function, spec?.name ?? "nil")
        spectrumTimer?.invalidate()
        guard let spec = spec else {return}
        spectrumTimer = Timer.scheduledTimer(withTimeInterval:SPECTRUM_INTERVAL, repeats:true) { timer in
            if spec.numberSummed > 0 {
                self.spectrumView.newData(source: spec)
            }
        }
    }

    var isTestSignal = false
    fileprivate func startTestSignal() {
        isTestSignal = true
        spectrumMenu.isEnabled = false
        let signal = TestSignal()
        signal.start()
        windowTitle = "Test Signal"
        startSpectrum(signal.spectrum)
        //Timer.scheduledTimer(withTimeInterval:5/*seconds*/, repeats:true) { timer in
        //    signal.processTime.printAccumulated(reset:true)
        //}
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // https://stackoverflow.com/a/29991529
        if ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil {
            // don't start receiver if unit testing
            return
        }

    #if true
        // TEMPORARY testing settings
        antennaSelect.selectItem(at:0/*Antenna A*/)
        //frequencyEntry.stringValue = "96300"
        //demodulatorSelect.selectItem(at:1/*Wide FM*/)
        frequencyEntry.stringValue = "1550"
        demodulatorSelect.selectItem(at:2/*AM*/)
        startSDR()
    #elseif true
        startTestSignal()
    #endif
        
    }
    
    override func viewDidAppear() {
        view.window?.title = windowTitle
        super.viewDidAppear()
        // transfer UI settings to receiver
        antennaAction(antennaSelect)
        frequencyAction(frequencyEntry)
        demodulatorAction(demodulatorSelect)
        spectrumChoiceAction(tunerSpectrumChoice!)
     }

    override func viewWillDisappear() {
        receive?.stopReceive()
        receive = nil
    }
    
    func setFrequency(_ val: String) {
        print("ViewController setFrequency", val)
        if let num = NumberFormatter().number(from: val),
           let tuner = receive?.tuner {
            let tuneHz = num.doubleValue * 1000.0
            tuner.tuneHz = tuneHz
            receive!.tunerSpectrum.centreHz = tuneHz
            spectrumView.rebuildAxis = true
            
            if tuneHz >= 88e6 && tuneHz <= 108e6 {
                demodulatorSelect.selectItem(at:1) // Wide FM
                demodulatorAction(demodulatorSelect)
            }
        }
    }
    
    @IBAction func frequencyAction(_ sender:NSTextField) {
        setFrequency(sender.stringValue)
    }
    
    @IBAction func antennaAction(_ sender:NSPopUpButton) {
        let val = sender.selectedItem!.title
        print("ViewController antennaAction", val)
        receive?.tuner.setOption(SDRplay.OptAntenna, val)
    }
    
    @IBAction func demodulatorAction(_ sender:NSPopUpButton) {
        let val = sender.selectedItem!.title
        print("ViewController demodulatorAction", val, sender.selectedItem!.tag)
        switch sender.selectedItem!.tag {
        case 0:
            receive?.setDemodulator(ReceiveSDR.Demodulator.None)
        case 1:
            receive?.setDemodulator(ReceiveSDR.Demodulator.WFM)
        case 2:
            receive?.setDemodulator(ReceiveSDR.Demodulator.AM)
        case 3:
            receive?.setDemodulator(ReceiveSDR.Demodulator.DSBSC)
        default:
            print("ViewController demodulatorAction invalid tag", val, sender.selectedItem!.tag)
        }
    }

    @IBAction func startStopAction(_ sender:NSButton) {
        let val = sender.state
        print("ViewController startStopAction", val.rawValue)
        sender.title = val == .off ? "Start" : "Stop"
        if val == .on {
            setFrequency(frequencyEntry!.stringValue)
            receive?.startReceive()
        } else {
            receive?.stopReceive()
        }
    }

    @IBOutlet weak var tunerSpectrumChoice: NSMenuItem!
    @IBOutlet weak var demodulatorSpectrumChoice: NSMenuItem!
    @IBOutlet weak var offSpectrumChoice: NSMenuItem!
    @IBAction func spectrumChoiceAction (_ sender: Any) {
        print(#function, sender)
        if isTestSignal { return }
        // all chocies off
        tunerSpectrumChoice.state = .off
        demodulatorSpectrumChoice.state = .off
        offSpectrumChoice.state = .off
        // sender choice on
        var spectrum:SpectrumData? = nil
        if let menuItem = sender as? NSMenuItem {
            menuItem.state = .on
            if menuItem == tunerSpectrumChoice {
                spectrum = receive?.tunerSpectrum
            } else if menuItem == demodulatorSpectrumChoice {
                spectrum = receive?.demodSwitch.currentDemod?.spectrum
            } else if menuItem == offSpectrumChoice {
                spectrum = nil
            } else {
                print(className, #function, "unexpected menu item", sender)
            }
        }
        // apply selection
        startSpectrum(spectrum)
    }

}
