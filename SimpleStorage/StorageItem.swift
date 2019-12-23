//
//  StoredObject.swift
//  Storage
//
//  Created by Dominik Gauggel on 11/12/19.
//  Copyright © 2019 couchbits GmbH. All rights reserved.
//

import Foundation

public struct StorageItem: Equatable {
    public let meta: Meta?
    public var values: [Any]

    public struct Meta: Equatable {
        public let id: UUID
        public let createdAt: Date
        public let updatedAt: Date

        public init(id: UUID, createdAt: Date, updatedAt: Date) {
            self.id = id
            self.createdAt = createdAt
            self.updatedAt = updatedAt
        }
    }

    public init(meta: Meta? = nil, values: [Any]) {
        self.values = values
        self.meta = meta
    }

    public func value<T>(index: Int) throws -> T {
        guard index >= 0 else { throw StorageError.invalidData("Negative index isn't allowed") }
        guard index < values.count else { throw StorageError.invalidData("Index out of bounds: \(index)") }
        guard let value = values[index] as? T else { throw StorageError.invalidData("Value \(values[index]) is not of type \(T.self)") }
        return value
    }
}

public func == (lhs: StorageItem, rhs: StorageItem) -> Bool {
    return lhs.meta == rhs.meta
}

public func == (lhs: StorageItem.Meta, rhs: StorageItem.Meta) -> Bool {
    return lhs.id == rhs.id && equals(lhs: lhs.createdAt, rhs: rhs.createdAt) && equals(lhs: lhs.updatedAt, rhs: rhs.updatedAt)
}

fileprivate func equals(lhs: Date, rhs: Date) -> Bool {
    return lhs.timeIntervalSince1970.isEqual(to: rhs.timeIntervalSince1970)
}
