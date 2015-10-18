//
//  Signal.swift
//  rvbw-ios
//
//  Created by Markus Gasser on 03.10.15.
//  Copyright © 2015 konoma GmbH. All rights reserved.
//

import Foundation
import PromiseKit


public class Signal<T>: CustomStringConvertible {
    
    // only access these vars from the signals queue
    private let signalQueue: dispatch_queue_t
    private let identifier: String
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
    
    private func createHandler(signalChain: SignalChain) -> SignalHandler<T> {
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


private class SignalChain {
    
    private var signalHandlers: [AnyObject] = []
    
    private func registerSignalHandler<T>(handler: SignalHandler<T>) {
        objc_sync_enter(self)
        defer { objc_sync_exit(self) }
        
        signalHandlers.append(handler)
    }
}

public class SignalHandler<T> {
    
    private typealias HandlerBlock = (Promise<T>) -> Void
    
    private let signalQueue: dispatch_queue_t
    private weak var signalChain: SignalChain?
    
    private init(signalQueue: dispatch_queue_t, registerOnChain signalChain: SignalChain) {
        self.signalQueue = signalQueue
        self.signalChain = signalChain
        
        signalChain.registerSignalHandler(self)
    }
    
    
    // only access these vars from the signals queue
    private var currentPromise: Promise<T>?
    private var handlers = [HandlerBlock]()
    
    
    // MARK: - Notify Results
    
    private func notifyNewPromise(promise: Promise<T>) {
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

public class SignalObserver {
    
    private var observingChains: [String: SignalChain] = [:]
    
    public func observe<T>(signal: Signal<T>) -> SignalHandler<T> {
        objc_sync_enter(self)
        defer { objc_sync_exit(self) }
        
        let signalChain = SignalChain()
        observingChains[signal.identifier] = signalChain
        
        return signal.createHandler(signalChain)
    }
    
    public func stopObserving<T>(signal: Signal<T>) {
        objc_sync_enter(self)
        defer { objc_sync_exit(self) }
        
        observingChains[signal.identifier] = nil
    }
}

private var defaultObserverKey: UInt = 0

extension NSObject {
    
    private var defaultObserver: SignalObserver {
        objc_sync_enter(self)
        defer { objc_sync_exit(self) }
        
        if let signalObserver = objc_getAssociatedObject(self, &defaultObserverKey) as? SignalObserver {
            return signalObserver
        }
        
        let observer = SignalObserver()
        objc_setAssociatedObject(self, &defaultObserverKey, observer, .OBJC_ASSOCIATION_RETAIN)
        return observer
    }
    
    public func observe<T>(signal: Signal<T>) -> SignalHandler<T> {
        return defaultObserver.observe(signal)
    }
    
    public func stopObserving<T>(signal: Signal<T>) {
        defaultObserver.stopObserving(signal)
    }
}

internal enum Result<T> {
    
    case Value(T)
    case Error(ErrorType)
    
    private func promise() -> Promise<T> {
        switch self {
        case .Value(let value): return Promise(value)
        case .Error(let error): return Promise(error: error)
        }
    }
}


private class WeakRef<T: AnyObject> {
    weak var value: T?
    
    init(_ value: T?) {
        self.value = value
    }
}
