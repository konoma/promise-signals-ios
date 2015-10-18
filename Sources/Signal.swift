//
//  Signal.swift
//  promise-signals-ios
//
//  Created by Markus Gasser on 18.10.15.
//  Copyright © 2015 konoma GmbH. All rights reserved.
//

import Foundation


public class Signal<T>: CustomStringConvertible {
    
    internal let identifier: String
    
    // only access these vars from the signals queue
    private let signalQueue: dispatch_queue_t
    private var handlers: [WeakRef<SignalHandler<T>>] = []
    private var currentResult: Result<T>?
    
    internal init(initial: T?) {
        let identifier = NSUUID().UUIDString
        
        self.signalQueue = dispatch_queue_create("\(identifier).signal-queue", DISPATCH_QUEUE_SERIAL)
        self.identifier = identifier
        
        if let value = initial {
            currentResult = .Value(value)
        }
    }
    
    
    // MARK: - Creating New Handlers
    
    internal func createHandler(signalChain: SignalChain) -> SignalHandler<T> {
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
    
    internal func notifyResult(result: Result<T>) {
        onSignalsQueue {
            // store the current result
            self.currentResult = result
            
            // pass all handlers a new promise
            for handlerRef in self.handlers {
                handlerRef.value?.notifyNewPromise(result.promise())
            }
            
            // prune deallocated SignalHandlers
            self.handlers = self.handlers.filter { $0.value != nil }
        }
    }
    
    
    // MARK: - CustomStringConvertible
    
    public var description: String {
        return "Signal(identifier=\(identifier))"
    }
    
    
    // MARK: - Helpers
    
    private func onSignalsQueue(block: () -> Void) {
        dispatch_async(signalQueue, block)
    }
}
