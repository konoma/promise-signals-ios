//
//  ViewController.swift
//  PromiseSignals
//
//  Created by Drew Pomerleau on 12/08/2016.
//  Copyright (c) 2016 Drew Pomerleau. All rights reserved.
//

import UIKit
import PromiseSignals

class ViewController: UIViewController {
    @IBOutlet var positiveCounterLabel: UILabel?
    @IBOutlet var negativeCounterLabel: UILabel?
    @IBOutlet var numberToSendTextField: UITextField?

    var positiveLabelValue: Int {
        get {
            return optionalStringToInteger(positiveCounterLabel?.text)
        }
        set {
            positiveCounterLabel?.text = String(newValue)
        }
    }

    var negativeLabelValue: Int {
        get {
            return optionalStringToInteger(negativeCounterLabel?.text)
        }
        set {
            negativeCounterLabel?.text = String(newValue)
        }
    }

    var numberToSend: Int {
        return optionalStringToInteger(numberToSendTextField?.text)
    }

    let signalObserver = SignalObserver()
    let signalControl = SignalControl<Int>()
    var signal: Signal<Int> { return signalControl.signal }

    override func viewDidLoad() {
        super.viewDidLoad()
        signalObserver.observe(signal).then { [weak self] value in
            self?.incrementPositiveCounter(change: value)
        }

        signalObserver.observe(signal).then { [weak self] value in
            self?.decrementNegativeCounter(change: value)
        }

        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func sendSignalButtonTapped() {
        signalControl.notifyValue(numberToSend)
    }

    func incrementPositiveCounter(change: Int) {
        positiveLabelValue += change
    }

    func decrementNegativeCounter(change: Int) {
        negativeLabelValue -= change
    }

    func optionalStringToInteger(_ str: String?, defaultValue: Int = 1) -> Int {
        guard let str = str, let numValue = Int(str) else {
            return defaultValue
        }

        return numValue
    }
}

