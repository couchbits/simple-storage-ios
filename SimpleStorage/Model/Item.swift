//
//  Item.swift
//  SimpleStorage
//
//  Created by Dominik Gauggel on 01.11.20.
//

import Foundation

public struct Item {
    public var id: UUID
    public var values: [String: StorableType]

    public init(id: UUID? = nil, values: [String: StorableType?]) {
        self.id = id ?? UUID()
        self.values = values.compactMapValues { $0 }
    }

    public func value<T: StorableType>(name: String) throws -> T {
        guard let value = values[name] as? T else { throw SimpleStorageError.invalidData("Value \(values[name] ?? "nil") is not of type \(T.self)") }
        return value
    }

    public func value<T: StorableType>(name: String) throws -> T? {
        return values[name] as? T
    }

    func value(name: String) throws -> UUID {
        if let uuid = values[name] as? UUID { return uuid }

        guard let uuidString: String = try value(name: name), let uuid = UUID(uuidString: uuidString) else {
            throw SimpleStorageError.invalidData("Value \(values[name] ?? "nil") is not of type UUID")
        }

        return uuid
    }

    func value(name: String) throws -> UUID? {
        guard let value = values[name] else { return nil }

        if let uuid = value as? UUID {
            return uuid
        }

        guard let uuidString: String = try self.value(name: name), let uuid = UUID(uuidString: uuidString) else {
            throw SimpleStorageError.invalidData("Value \(values[name] ?? "nil") is not of type UUID")
        }

        return uuid
    }

    func value(name: String) throws -> Bool {
        let integerValue: Int = try value(name: name)
        return integerValue != 0
    }

    func value(name: String) throws -> Bool? {
        guard let integerValue: Int = try value(name: name) else { return nil }
        return integerValue != 0
    }

    func value(name: String) throws -> Date {
        let doubleValue: Double = try value(name: name)
        return Date(timeIntervalSince1970: doubleValue)
    }

    func value(name: String) throws -> Date? {
        guard let doubleValue: Double = try value(name: name) else { return nil }
        return Date(timeIntervalSince1970: doubleValue)
    }
}
