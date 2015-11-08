//
//  SignalChain.swift
//  promise-signals-ios
//
//  Created by Markus Gasser on 18.10.15.
//  Copyright © 2015 konoma GmbH. All rights reserved.
//

import Foundation


internal class SignalChain {
    
    private var signalHandlers: [AnyObject] = []
    
    internal func registerSignalHandler<T>(handler: SignalHandler<T>) {
        synchronized(self) {
            signalHandlers.append(handler)
        }
    }
}
