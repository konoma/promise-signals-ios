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
    
    case value(T)
    case error(Error)
    
    internal func promise() -> Promise<T> {
        switch self {
        case .value(let value): return Promise(value: value)
        case .error(let error): return Promise(error: error)
        }
    }
}


internal class WeakRef<T: AnyObject> {

    weak var value: T?
    
    internal init(_ value: T?) {
        self.value = value
    }
}


internal func synchronized<T>(_ lock: AnyObject, criticalSection: () throws -> T) rethrows -> T {
    objc_sync_enter(lock)
    defer { objc_sync_exit(lock) }
    
    return try criticalSection()
}
