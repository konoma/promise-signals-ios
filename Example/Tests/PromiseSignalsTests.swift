//
//  promise_signals_iosTests.swift
//  promise-signals-iosTests
//
//  Created by Markus Gasser on 18.10.15.
//  Copyright © 2015 konoma GmbH. All rights reserved.
//

import XCTest
import Foundation
import Nimble

@testable import PromiseSignals


class PromiseSignalsTests: XCTestCase {
    
    let count = 10000
    
    let signalObserver = SignalObserver()
    let signalControl = SignalControl<Int>()
    var signal: Signal<Int> { return signalControl.signal }
    
    func testSignalAppliedFirstReportsAllValues() {
        var notifiedValues = [Int]()
        let expectedValues = Array(0 ..< count)

        _ = signalObserver.observe(signal).then { value in
            notifiedValues.append(value)
        }
        
        doInBackgroundSerial(count: count) { i in
            self.signalControl.notifyValue(i)
        }
        
        expect(notifiedValues).toEventually(equal(expectedValues), timeout: 10)
    }
    
    func testSignalAppliedLastReportsLastValue() {
        var notifiedValues = [Int]()
        let expectedValues = [count-1]

        doInBackgroundSerial(count: count) { i in
            self.signalControl.notifyValue(i)
        }
        
        signalObserver.observe(signal).then { value in
            notifiedValues.append(value)
        }
        
        expect(notifiedValues).toEventually(equal(expectedValues), timeout: 10)
    }
    
    func testSignalAppliedFirstReportsAllValuesInParallel() {
        var notifiedValues = Set<Int>()
        let expectedValues = Set(0 ..< count)

        signalObserver.observe(signal).then { value in
            notifiedValues.insert(value)
        }

        doInBackgroundParallel(count: count) { i in
            self.signalControl.notifyValue(i)
        }
        
        expect(notifiedValues).toEventually(equal(expectedValues), timeout: 10)
    }
    
    func testSignalAppliedLastReportsLastValueInParallel() {
        var notifiedValues = Set<Int>()
        
        doInBackgroundParallel(count: count) { i in
            self.signalControl.notifyValue(i)
        }
        
        signalObserver.observe(signal).then { value in
            notifiedValues.insert(value)
        }
        
        expect(notifiedValues.count).toEventually(equal(1), timeout: 10)
        expect(notifiedValues.first ?? -1).toEventually(beGreaterThanOrEqualTo(0), timeout: 10)
        expect(notifiedValues.first ?? -1).toEventually(beLessThan(count), timeout: 10)
    }
    
    func testObservingUsingMultipleHandlersGoesWellIfAppliedFirst() {
        var reported = 0
        
        self.signalControl.notifyValue(10)
        
        doInBackgroundParallel(count: count) { i in
            self.signalObserver.observe(self.signal).then { value in
                expect(value) == 10
                reported += 1
            }
        }
        
        expect(reported).toEventually(equal(count), timeout: 10)
    }
}
