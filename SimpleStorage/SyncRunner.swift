//
//  SyncRunner.swift
//  SimpleStorage
//
//  Created by Dominik Gauggel on 06.02.20.
//  Copyright © 2019 couchbits GmbH. All rights reserved.
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
        var caughtValue: T?
        var caughtError: Error?

        queue.sync {
            do {
                caughtValue = try block()
            } catch {
                caughtError = error
            }
        }
        if let error = caughtError {
            throw error
        }

        guard let value = caughtValue else { fatalError() }
        return value
    }

    func run(_ block: () throws -> Void) throws {
        var caughtError: Error?

        queue.sync {
            do {
                try block()
            } catch {
                caughtError = error
            }
        }

        if let error = caughtError {
            throw error
        }
    }
}
