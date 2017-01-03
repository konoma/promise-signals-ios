//
//  Utils.swift
//  promise-signals-ios
//
//  Created by Markus Gasser on 08.11.15.
//  Copyright © 2015 konoma GmbH. All rights reserved.
//

import Foundation


let backgroundQueue = DispatchQueue(label: "promise-signals-test-background-queue", attributes: .concurrent)


func doInBackgroundSerial(count: Int, action: @escaping (Int) -> Void) {
    backgroundQueue.sync {
        for i in 0 ..< count {
            action(i)
        }
    }
}

func doInBackgroundParallel(count: Int, action: @escaping (Int) -> Void) {
    backgroundQueue.async {
        DispatchQueue.concurrentPerform(iterations: count, execute: action)
    }
}
