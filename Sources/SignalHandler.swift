//
//  SignalHandler.swift
//  promise-signals-ios
//
//  Created by Markus Gasser on 18.10.15.
//  Copyright © 2015 konoma GmbH. All rights reserved.
//

import Foundation
import PromiseKit


public class SignalHandler<T> {
    
    private typealias HandlerBlock = (Promise<T>) -> Void
    
    
    private let signalQueue: dispatch_queue_t
    private weak var signalChain: SignalChain?
    
    internal init(signalQueue: dispatch_queue_t, registerOnChain signalChain: SignalChain) {
        self.signalQueue = signalQueue
        self.signalChain = signalChain
        
        signalChain.registerSignalHandler(self)
    }
    
    
    // only access these vars from the signals queue
    private var currentPromise: Promise<T>?
    private var handlers = [HandlerBlock]()
    
    
    // MARK: - Notify Results
    
    internal func notifyNewPromise(promise: Promise<T>) {
        // must be called on the signal queue
        
        currentPromise = promise
        
        // apply all handler blocks to the new promise
        for handler in handlers {
            handler(promise)
        }
    }
    
    
    // MARK: - Promise Methods
    
    public func then<U>(on q: dispatch_queue_t = dispatch_get_main_queue(), _ body: (T) throws -> Promise<U>) -> SignalHandler<U> {
        let signalHandler = SignalHandler<U>(signalQueue: signalQueue, registerOnChain: signalChain!)
        
        applyAndRegisterTransformer(nextHandler: signalHandler) { promise in
            return promise.then(on: q, body)
        }
        
        return signalHandler
    }
    
    public func then<U>(on q: dispatch_queue_t = dispatch_get_main_queue(), _ body: (T) throws -> U) -> SignalHandler<U> {
        let signalHandler = SignalHandler<U>(signalQueue: signalQueue, registerOnChain: signalChain!)
        
        applyAndRegisterTransformer(nextHandler: signalHandler) { promise in
            return promise.then(on: q, body)
        }
        
        return signalHandler
    }
    
    public func thenInBackground<U>(body: (T) throws -> U) -> SignalHandler<U> {
        return then(on: dispatch_get_global_queue(0, 0), body)
    }
    
    public func thenInBackground<U>(body: (T) throws -> Promise<U>) -> SignalHandler<U> {
        return then(on: dispatch_get_global_queue(0, 0), body)
    }
    
    public func error(policy policy: ErrorPolicy = .AllErrorsExceptCancellation, _ body: (ErrorType) -> Void) {
        applyAndRegisterTransformer { promise in
            promise.error(policy: policy, body)
        }
    }
    
    public func recover(on q: dispatch_queue_t = dispatch_get_main_queue(), _ body: (ErrorType) throws -> Promise<T>) -> SignalHandler<T> {
        let signalHandler = SignalHandler(signalQueue: signalQueue, registerOnChain: signalChain!)
        
        applyAndRegisterTransformer(nextHandler: signalHandler) { promise in
            return promise.recover(on: q, body)
        }
        
        return signalHandler
    }
    
    public func recover(on q: dispatch_queue_t = dispatch_get_main_queue(), _ body: (ErrorType) throws -> T) -> SignalHandler<T> {
        let signalHandler = SignalHandler(signalQueue: signalQueue, registerOnChain: signalChain!)
        
        applyAndRegisterTransformer(nextHandler: signalHandler) { promise in
            return promise.recover(on: q, body)
        }
        
        return signalHandler
    }
    
    public func always(on q: dispatch_queue_t = dispatch_get_main_queue(), _ body: () -> Void) -> SignalHandler<T> {
        let signalHandler = SignalHandler(signalQueue: signalQueue, registerOnChain: signalChain!)
        
        applyAndRegisterTransformer(nextHandler: signalHandler) { promise in
            return promise.always(on: q, body)
        }
        
        return signalHandler
    }
    
    
    // MARK: - Helpers
    
    private func applyAndRegisterTransformer(transformer: (Promise<T>) -> Void) {
        let wrappedTransformer = { (promise: Promise<T>) -> Promise<Void>? in
            transformer(promise)
            return nil
        }
        
        applyAndRegisterTransformer(nextHandler: nil, transformer: wrappedTransformer)
    }
    
    private func applyAndRegisterTransformer<U>(nextHandler nextHandler: SignalHandler<U>?, transformer: (Promise<T>) -> Promise<U>?) {
        onSignalsQueue {
            weak var weakChild = nextHandler
            
            // transform the promise and apply to a child if necessary
            let handlerBlock: HandlerBlock = { promise in
                if let childPromise = transformer(promise) {
                    weakChild?.notifyNewPromise(childPromise)
                }
            }
            
            // apply the handler block to the current promise if necessary
            if let promise = self.currentPromise {
                handlerBlock(promise)
            }
            
            // register the handler bock for future promise updates
            self.handlers.append(handlerBlock)
        }
    }
    
    private func onSignalsQueue(block: () -> Void) {
        dispatch_async(signalQueue, block)
    }
}
