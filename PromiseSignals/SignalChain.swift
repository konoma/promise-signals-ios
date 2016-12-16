//
//  SignalChain.swift
//  promise-signals-ios
//
//  Created by Markus Gasser on 18.10.15.
//  Copyright © 2015 konoma GmbH. All rights reserved.
//

import Foundation


internal class SignalChain {
    
    fileprivate var signalHandlers: [AnyObject] = []
    
    internal func registerSignalHandler<T>(_ handler: SignalHandler<T>) {
        synchronized(lock: self) {
            signalHandlers.append(handler)
        }
    }
}
