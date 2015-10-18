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
        currentPromise = promise
        
        for handler in handlers {
            handler(promise)
        }
    }
    
    
    // MARK: - Promise Methods
    
    public func then<U>(on q: dispatch_queue_t = dispatch_get_main_queue(), _ body: (T) throws -> U) -> SignalHandler<U> {
        return then(on: q, { Promise(try body($0)) })
    }
    
    public func then<U>(on q: dispatch_queue_t = dispatch_get_main_queue(), _ body: (T) throws -> Promise<U>) -> SignalHandler<U> {
        let signalHandler = SignalHandler<U>(signalQueue: signalQueue, registerOnChain: signalChain!)
        
        onSignalsQueue {
            weak var weakChild = signalHandler
            
            let handlerBlock: HandlerBlock = { promise in
                let childPromise = promise.then(on: q, body)
                weakChild?.notifyNewPromise(childPromise)
            }
            
            if let promise = self.currentPromise {
                handlerBlock(promise)
            }
            
            self.handlers.append(handlerBlock)
        }
        
        return signalHandler
    }
    
    
    // MARK: - Helpers
    
    private func onSignalsQueue(block: () -> Void) {
        dispatch_async(signalQueue, block)
    }
}
