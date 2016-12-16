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
    
    let count = 100
    
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
            self.signalControl.notify(value: i)
        }
        
        expect(notifiedValues).toEventually(equal(expectedValues), timeout: 2)
    }
    
    func testSignalAppliedLastReportsLastValue() {
        var notifiedValues = [Int]()
        let expectedValues = [count-1]

        doInBackgroundSerial(count: count) { i in
            self.signalControl.notify(value: i)
        }
        
        signalObserver.observe(signal).then { value in
            notifiedValues.append(value)
        }
        
        expect(notifiedValues).toEventually(equal(expectedValues), timeout: 2)
    }
    
    func testSignalAppliedFirstReportsAllValuesInParallel() {
        var notifiedValues = Set<Int>()
        let expectedValues = Set(0 ..< count)

        signalObserver.observe(signal).then { value in
            notifiedValues.insert(value)
        }

        doInBackgroundParallel(count: count) { i in
            self.signalControl.notify(value: i)
        }
        
        expect(notifiedValues).toEventually(equal(expectedValues), timeout: 2)
    }
    
    func testSignalAppliedLastReportsLastValueInParallel() {
        var notifiedValues = Set<Int>()

        doInBackgroundParallel(count: count) { i in
            self.signalControl.notify(value: i)
        }
        
        signalObserver.observe(signal).then { value in
            notifiedValues.insert(value)
        }

        expect(notifiedValues.count).toEventually(equal(count), timeout: 2.0)
        expect(notifiedValues.min()).toEventually(equal(1), timeout: 2.0)
        expect(notifiedValues.max()).toEventually(equal(count), timeout: 2.0)
    }
    
    func testObservingUsingMultipleHandlersGoesWellIfAppliedFirst() {
        var reported = 0
        
        self.signalControl.notify(value: 10)
        
        doInBackgroundParallel(count: count) { i in
            self.signalObserver.observe(self.signal).then { value in
                expect(value) == 10
                reported += 1
            }
        }
        
        expect(reported).toEventually(equal(count), timeout: 2)
    }
}
