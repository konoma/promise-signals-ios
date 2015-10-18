//
//  SignalControl.swift
//  promise-signals-ios
//
//  Created by Markus Gasser on 18.10.15.
//  Copyright © 2015 konoma GmbH. All rights reserved.
//

import Foundation


public class SignalControl<T> {
    
    public let signal: Signal<T>
    
    public convenience init(initialValue: T) {
        self.init(initial: initialValue)
    }
    
    public convenience init() {
        self.init(initial: nil)
    }
    
    private init(initial: T?) {
        self.signal = Signal(initial: initial)
    }
    
    public func notifyValue(value: T) {
        signal.notifyResult(.Value(value))
    }
    
    public func notifyError(error: ErrorType) {
        signal.notifyResult(.Error(error))
    }
}
