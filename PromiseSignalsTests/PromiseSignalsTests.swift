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

        signalObserver.observe(signal).map { value in
            notifiedValues.append(value)
        }

        doInBackgroundSerial(count: count) { value in
            self.signalControl.notify(value: value)
        }

        expect(notifiedValues).toEventually(equal(expectedValues), timeout: 2)
    }

    func testSignalAppliedLastReportsLastValue() {
        var notifiedValues = [Int]()
        let expectedValues = [count-1]

        doInBackgroundSerial(count: count) { value in
            self.signalControl.notify(value: value)
        }

        signalObserver.observe(signal).map { value in
            notifiedValues.append(value)
        }

        expect(notifiedValues).toEventually(equal(expectedValues), timeout: 2)
    }

    func testSignalAppliedFirstReportsAllValuesInParallel() {
        var notifiedValues = Set<Int>()
        let expectedValues = Set(0 ..< count)

        signalObserver.observe(signal).map { value in
            notifiedValues.insert(value)
        }

        doInBackgroundParallel(count: count) { value in
            self.signalControl.notify(value: value)
        }

        expect(notifiedValues).toEventually(equal(expectedValues), timeout: 2)
    }

    func testSignalAppliedLastReportsLastValueInParallel() {
        var notifiedValues = Set<Int>()

        doInBackgroundParallel(count: count) { value in
            self.signalControl.notify(value: value)
        }

        signalObserver.observe(signal).map { value in
            notifiedValues.insert(value)
        }

        expect(notifiedValues.max()).toEventually(equal(count - 1), timeout: 2.0)
    }

    func testObservingUsingMultipleHandlersGoesWellIfAppliedFirst() {
        var reported = 0

        self.signalControl.notify(value: 10)

        doInBackgroundParallel(count: count) { _ in
            self.signalObserver.observe(self.signal).map { value in
                expect(value) == 10
                reported += 1
            }
        }

        expect(reported).toEventually(equal(count), timeout: 2)
    }
}
