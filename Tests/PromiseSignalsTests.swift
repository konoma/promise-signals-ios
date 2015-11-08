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
    
    let count = 1000
    
    let signalObserver = SignalObserver()
    let signalControl = SignalControl<Int>()
    var signal: Signal<Int> { return signalControl.signal }
    
    func testSignalAppliedFirstReportsAllValues() {
        let notifiedValues = NSMutableArray()
        let expectedValues = NSArray(range: 0 ..< count)
        
        signalObserver.observe(signal).then { value in
            notifiedValues.addObject(value)
        }
        
        doInBackgroundSerial(count: count) { i in
            self.signalControl.notifyValue(i)
        }
        
        expect(notifiedValues).toEventually(equal(expectedValues), timeout: 10)
    }
    
    func testSignalAppliedLastReportsLastValue() {
        let notifiedValues = NSMutableArray()
        let expectedValues = NSArray(object: count - 1)
        
        doInBackgroundSerial(count: count) { i in
            self.signalControl.notifyValue(i)
        }
        
        signalObserver.observe(signal).then { value in
            notifiedValues.addObject(value)
        }
        
        expect(notifiedValues).toEventually(equal(expectedValues), timeout: 10)
    }
    
    func testSignalAppliedFirstReportsAllValuesInParallel() {
        let notifiedValues = NSMutableSet()
        let expectedValues = NSSet(range: 0 ..< count)
        
        signalObserver.observe(signal).then { value in
            notifiedValues.addObject(value)
        }
        
        doInBackgroundParallel(count: count) { i in
            self.signalControl.notifyValue(i)
        }
        
        expect(notifiedValues).toEventually(equal(expectedValues), timeout: 10)
    }
    
    func testSignalAppliedLastReportsLastValueInParallel() {
        let notifiedValues = NSMutableSet()
        
        doInBackgroundParallel(count: count) { i in
            self.signalControl.notifyValue(i)
        }
        
        signalObserver.observe(signal).then { value in
            notifiedValues.addObject(value)
        }
        
        expect(notifiedValues.count).toEventually(equal(1), timeout: 10)
        expect((notifiedValues.anyObject() as? Int) ?? -1).toEventually(beGreaterThanOrEqualTo(0), timeout: 10)
        expect((notifiedValues.anyObject() as? Int) ?? -1).toEventually(beLessThan(count), timeout: 10)
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
