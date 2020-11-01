//
//  SyncRunner.swift
//  SimpleStorage
//
//  Created by Dominik Gauggel on 31.10.20.
//

import Foundation

protocol SyncRunner {
    func run<T>(_ block: () throws -> T) throws -> T
    func run(_ block: () throws -> Void) throws
}

class DefaultSyncRunner {
    let queue = DispatchQueue(label: "com.couchbits.simplestorage.syncrunner", qos: .default)
}

extension DefaultSyncRunner: SyncRunner {
    func run<T>(_ block: () throws -> T) throws -> T {
        return try queue.sync {
            return try block()
        }
    }

    func run(_ block: () throws -> Void) throws {
        try queue.sync {
            try block()
        }
    }
}

