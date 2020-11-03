//
//  Item.swift
//  SimpleStorage
//
//  Created by Dominik Gauggel on 01.11.20.
//

import Foundation

public struct Item {
    public let id: UUID
    var values: [String: StorableType]

    public init(values: [String: StorableType?]) throws {
        let nonNilableValues = values.compactMapValues { $0 }
        self.values = nonNilableValues
        self.id = try Item.id(values: nonNilableValues)
    }

    public init(id: UUID, values: [String: StorableType?]) {
        self.id = id
        self.values = values.compactMapValues { $0 }.filter { $0.key != "id" }
    }

    static func id(values: [String: StorableType]) throws -> UUID {
        guard let value = values["id"] else { return UUID() }
        if let id = value as? UUID {
            return id
        } else if let idString = value as? String, let id = UUID(uuidString: idString) {
            return id
        }
        throw SimpleStorageError.invalidData("id has invalid type \(value.self)")
    }

    private func storableTypeValue<T: StorableType>(name: String) throws -> T {
        guard let value = values[name] as? T else { throw SimpleStorageError.invalidData("Value \(values[name] ?? "nil") is not of type \(T.self)") }
        return value
    }

    private func storableTypeValue<T: StorableType>(name: String) throws -> T? {
        return values[name] as? T
    }

    public func value(name: String) throws -> String {
        return try storableTypeValue(name: name)
    }

    public func value(name: String) throws -> String? {
        return try storableTypeValue(name: name)
    }

    public func value(name: String) throws -> Int {
        return try storableTypeValue(name: name)
    }

    public func value(name: String) throws -> Int? {
        return try storableTypeValue(name: name)
    }

    public func value(name: String) throws -> Double {
        return try storableTypeValue(name: name)
    }

    public func value(name: String) throws -> Double? {
        return try storableTypeValue(name: name)
    }

    public func value(name: String) throws -> UUID {
        if let uuid = values[name] as? UUID { return uuid }

        guard let uuidString: String = try storableTypeValue(name: name), let uuid = UUID(uuidString: uuidString) else {
            throw SimpleStorageError.invalidData("Value \(values[name] ?? "nil") is not of type UUID")
        }

        return uuid
    }

    public func value(name: String) throws -> UUID? {
        guard let value = values[name] else { return nil }

        if let uuid = value as? UUID {
            return uuid
        }

        guard let uuidString: String = try self.storableTypeValue(name: name), let uuid = UUID(uuidString: uuidString) else {
            throw SimpleStorageError.invalidData("Value \(values[name] ?? "nil") is not of type UUID")
        }

        return uuid
    }

    public func value(name: String) throws -> Bool {
        let integerValue: Int = try storableTypeValue(name: name)
        return integerValue != 0
    }

    public func value(name: String) throws -> Bool? {
        guard let integerValue: Int = try storableTypeValue(name: name) else { return nil }
        return integerValue != 0
    }

    public func value(name: String) throws -> Date {
        let doubleValue: Double = try storableTypeValue(name: name)
        return Date(timeIntervalSince1970: doubleValue)
    }

    public func value(name: String) throws -> Date? {
        guard let doubleValue: Double = try storableTypeValue(name: name) else { return nil }
        return Date(timeIntervalSince1970: doubleValue)
    }
}
