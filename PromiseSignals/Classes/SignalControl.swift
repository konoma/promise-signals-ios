//
//  SignalControl.swift
//  promise-signals-ios
//
//  Created by Markus Gasser on 18.10.15.
//  Copyright © 2015 konoma GmbH. All rights reserved.
//

import Foundation


open class SignalControl<T> {
    
    open let signal: Signal<T>
    
    public convenience init(initialValue: T) {
        self.init(initial: initialValue)
    }
    
    public convenience init() {
        self.init(initial: nil)
    }
    
    fileprivate init(initial: T?) {
        self.signal = Signal(initial: initial)
    }
    
    open func notifyValue(_ value: T) {
        signal.notifyResult(.value(value))
    }
    
    open func notifyError(_ error: Error) {
        signal.notifyResult(.error(error))
    }
}
