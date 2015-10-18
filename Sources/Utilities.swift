//
//  Utilities.swift
//  promise-signals-ios
//
//  Created by Markus Gasser on 18.10.15.
//  Copyright © 2015 konoma GmbH. All rights reserved.
//

import Foundation
import PromiseKit


internal enum Result<T> {
    
    case Value(T)
    case Error(ErrorType)
    
    internal func promise() -> Promise<T> {
        switch self {
        case .Value(let value): return Promise(value)
        case .Error(let error): return Promise(error: error)
        }
    }
}


internal class WeakRef<T: AnyObject> {
    weak var value: T?
    
    internal init(_ value: T?) {
        self.value = value
    }
}


internal func synchronized<T>(lock: AnyObject, @noescape criticalSection: () throws -> T) rethrows -> T {
    objc_sync_enter(lock)
    defer { objc_sync_exit(lock) }
    
    return try criticalSection()
}
