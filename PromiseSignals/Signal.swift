//
//  Signal.swift
//  promise-signals-ios
//
//  Created by Markus Gasser on 18.10.15.
//  Copyright © 2015 konoma GmbH. All rights reserved.
//

import Foundation


open class Signal<T>: CustomStringConvertible {
    
    internal let identifier: String
    
    // only access these vars from the signals queue
    fileprivate let signalQueue: DispatchQueue
    fileprivate var handlers: [WeakRef<SignalHandler<T>>] = []
    fileprivate var currentResult: Result<T>?
    
    internal init(initial: T?) {
        let identifier = UUID().uuidString
        
        self.signalQueue = DispatchQueue(label: "\(identifier).signal-queue", attributes: [])
        self.identifier = identifier
        
        if let value = initial {
            currentResult = .value(value)
        }
    }
    
    
    // MARK: - Creating New Handlers
    
    internal func createHandler(_ signalChain: SignalChain) -> SignalHandler<T> {
        let signalHandler = SignalHandler<T>(signalQueue: signalQueue, registerOnChain: signalChain)
        
        onSignalsQueue {
            self.handlers.append(WeakRef(signalHandler))
            
            if let result = self.currentResult {
                signalHandler.notifyNewPromise(result.promise())
            }
        }
        
        return signalHandler
    }
    
    
    // MARK: - Notify Values and Errors
    
    internal func notifyResult(_ result: Result<T>) {
        onSignalsQueue {
            // store the current result
            self.currentResult = result
            
            // pass all handlers a new promise
            let promise = result.promise()
            for handlerRef in self.handlers {
                handlerRef.value?.notifyNewPromise(promise)
            }
            
            // prune deallocated SignalHandlers
            self.handlers = self.handlers.filter { $0.value != nil }
        }
    }
    
    
    // MARK: - CustomStringConvertible
    
    open var description: String {
        return "Signal(identifier=\(identifier))"
    }
    
    
    // MARK: - Helpers
    
    fileprivate func onSignalsQueue(_ block: @escaping () -> Void) {
        signalQueue.async(execute: block)
    }
}
