//
//  SignalObserver.swift
//  promise-signals-ios
//
//  Created by Markus Gasser on 18.10.15.
//  Copyright © 2015 konoma GmbH. All rights reserved.
//

import Foundation


private var defaultObserverKey: UInt = 0


public class SignalObserver {
    
    private var observingChains: [String: SignalChain] = [:]
    
    public init() {}
    
    public func observe<T>(signal: Signal<T>) -> SignalHandler<T> {
        return synchronized(self) {
            return signal.createHandler(signalChainForIdentifier(signal.identifier))
        }
    }
    
    public func stopObserving<T>(signal: Signal<T>) {
        synchronized(self) {
            observingChains[signal.identifier] = nil
        }
    }
    
    private func signalChainForIdentifier(identifier: String) -> SignalChain {
        if let chain = observingChains[identifier] {
            return chain
        }
        
        let chain = SignalChain()
        observingChains[identifier] = chain
        return chain
    }
}


extension NSObject {
    
    private var defaultObserver: SignalObserver {
        return synchronized(self) {
            if let signalObserver = objc_getAssociatedObject(self, &defaultObserverKey) as? SignalObserver {
                return signalObserver
            }
            
            let observer = SignalObserver()
            objc_setAssociatedObject(self, &defaultObserverKey, observer, .OBJC_ASSOCIATION_RETAIN)
            return observer
        }
    }
    
    public func observe<T>(signal: Signal<T>) -> SignalHandler<T> {
        return defaultObserver.observe(signal)
    }
    
    public func stopObserving<T>(signal: Signal<T>) {
        defaultObserver.stopObserving(signal)
    }
}
