//
//  Utils.swift
//  promise-signals-ios
//
//  Created by Markus Gasser on 08.11.15.
//  Copyright © 2015 konoma GmbH. All rights reserved.
//

import Foundation


let backgroundQueue = dispatch_queue_create("promise-signals-test-background-queue", DISPATCH_QUEUE_CONCURRENT)


func doInBackgroundSerial(count count: Int, action: (Int) -> Void) {
    dispatch_sync(backgroundQueue) {
        for i in 0 ..< count {
            action(i)
        }
    }
}

func doInBackgroundParallel(count count: Int, action: (Int) -> Void) {
    dispatch_apply(count, backgroundQueue, action)
}


extension NSArray {
    
    convenience init(range: Range<Int>) {
        self.init(array: Array(range: range))
    }
}

extension NSSet {
    
    convenience init(range: Range<Int>) {
        self.init(array: Array(range: range))
    }
}

extension Array where Element: ForwardIndexType {
    
    init(range: Range<Element>) {
        self.init(range.generate())
    }
}
