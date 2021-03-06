//
//  Item.swift
//  SimpleStorage
//
//  Created by Dominik Gauggel on 01.11.20.
//

import Foundation

public struct Item {
    public let id: UUID
    var values: [String: StorableDataType]

    public init(values: [String: StorableDataType?]) {
        if let id = values["id"] as? UUID {
            self.id = id
        } else if let idString = values["id"] as? String, let id = UUID(uuidString: idString) {
            self.id = id
        } else {
            self.id = UUID()
        }
        var values = values.compactMapValues { $0 }
        values["id"] = id
        self.values = values
    }

    public init(id: UUID, values: [String: StorableDataType?]) {
        self.id = id
        var values = values.compactMapValues { $0 }
        values["id"] = id
        self.values = values
    }

    private func storableTypeValue<T: StorableDataType>(name: String) throws -> T {
        guard let value = values[name] as? T else { throw SimpleStorageError.invalidData("Value \(values[name] ?? "nil") is not of type \(T.self)") }
        return value
    }

    private func storableTypeValue<T: StorableDataType>(name: String) throws -> T? {
        return values[name] as? T
    }

    public mutating func setValue(name: String, value: StorableDataType) {
        values[name] = value
    }

    public func value(name: String) throws -> String {
        if let uuid = values[name] as? UUID {
            return uuid.uuidString
        } else {
            return try storableTypeValue(name: name)
        }
    }

    public func value(name: String) throws -> String? {
        guard let value = values[name] else { return nil }

        if let uuid = value as? UUID {
            return uuid.uuidString
        } else {
            return try storableTypeValue(name: name)
        }
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

        guard let uuidString: String = try storableTypeValue(name: name),
              let uuid = UUID(uuidString: uuidString) else {
            throw SimpleStorageError.invalidData("Value \(values[name] ?? "nil") is not of type UUID")
        }

        return uuid
    }

    public func value(name: String) throws -> UUID? {
        guard let value = values[name] else { return nil }

        if let uuid = value as? UUID {
            return uuid
        }

        guard let uuidString: String = try self.storableTypeValue(name: name),
              let uuid = UUID(uuidString: uuidString) else {
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
        if let date = values[name] as? Date { return date }

        let doubleValue: Double = try storableTypeValue(name: name)
        return Date(timeIntervalSince1970: doubleValue)
    }

    public func value(name: String) throws -> Date? {
        guard let value = values[name] else { return nil }

        if let date = value as? Date {
            return date
        }

        guard let doubleValue: Double = try self.storableTypeValue(name: name) else {
            throw SimpleStorageError.invalidData("Value \(values[name] ?? "nil") is not of type UUID")
        }

        return Date(timeIntervalSince1970: doubleValue)
    }
}
