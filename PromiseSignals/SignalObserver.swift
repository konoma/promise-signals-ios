//
//  SignalObserver.swift
//  promise-signals-ios
//
//  Created by Markus Gasser on 18.10.15.
//  Copyright © 2015 konoma GmbH. All rights reserved.
//

import Foundation


public class SignalObserver {
    
    fileprivate var observingChains: [String: SignalChain] = [:]
    
    public init() {}
    
    public func observe<T>(_ signal: Signal<T>) -> SignalHandler<T> {
        return synchronized(self) {
            return signal.createHandler(signalChain: signalChain(for: signal.identifier))
        }
    }
    
    public func stopObserving<T>(_ signal: Signal<T>) {
        synchronized(self) {
            observingChains[signal.identifier] = nil
        }
    }
    
    fileprivate func signalChain(for identifier: String) -> SignalChain {
        if let chain = observingChains[identifier] {
            return chain
        }
        
        let chain = SignalChain()
        observingChains[identifier] = chain
        return chain
    }
}


public extension NSObject {

    fileprivate static var defaultObserverKey: UInt = 0

    fileprivate var defaultObserver: SignalObserver {
        return synchronized(self) {
            if let signalObserver = objc_getAssociatedObject(self, &NSObject.defaultObserverKey) as? SignalObserver {
                return signalObserver
            }
            
            let observer = SignalObserver()
            objc_setAssociatedObject(self, &NSObject.defaultObserverKey, observer, .OBJC_ASSOCIATION_RETAIN)
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
