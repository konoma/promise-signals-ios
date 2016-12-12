//
//  SignalObserver.swift
//  promise-signals-ios
//
//  Created by Markus Gasser on 18.10.15.
//  Copyright © 2015 konoma GmbH. All rights reserved.
//

import Foundation


private var defaultObserverKey: UInt = 0


open class SignalObserver {
    
    fileprivate var observingChains: [String: SignalChain] = [:]
    
    public init() {}
    
    open func observe<T>(_ signal: Signal<T>) -> SignalHandler<T> {
        return synchronized(lock: self) {
            return signal.createHandler(signalChainForIdentifier(signal.identifier))
        }
    }
    
    open func stopObserving<T>(_ signal: Signal<T>) {
        synchronized(lock: self) {
            observingChains[signal.identifier] = nil
        }
    }
    
    fileprivate func signalChainForIdentifier(_ identifier: String) -> SignalChain {
        if let chain = observingChains[identifier] {
            return chain
        }
        
        let chain = SignalChain()
        observingChains[identifier] = chain
        return chain
    }
}


extension NSObject {
    
    fileprivate var defaultObserver: SignalObserver {
        return synchronized(lock: self) {
            if let signalObserver = objc_getAssociatedObject(self, &defaultObserverKey) as? SignalObserver {
                return signalObserver
            }
            
            let observer = SignalObserver()
            objc_setAssociatedObject(self, &defaultObserverKey, observer, .OBJC_ASSOCIATION_RETAIN)
            return observer
        }
    }
    
    public func observe<T>(_ signal: Signal<T>) -> SignalHandler<T> {
        return defaultObserver.observe(signal)
    }
    
    public func stopObserving<T>(_ signal: Signal<T>) {
        defaultObserver.stopObserving(signal)
    }
}
