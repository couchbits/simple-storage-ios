//
//  SimpleStorageType.swift
//  SimpleStorage
//
//  Created by Dominik Gauggel on 02.11.20.
//

import Foundation

public class SimpleStorageType: Equatable {
    let simpleStorage: SimpleStorage
    public let storageType: String

    public init(simpleStorage: SimpleStorage, storageType: String) throws {
        self.simpleStorage = simpleStorage
        self.storageType = storageType

        try simpleStorage.createStorageType(storageType: storageType)
    }

    public func removeStorageType() throws {
        try simpleStorage.removeStorageType(storageType: storageType)
    }

    public func addAttribute(attribute: Attribute) throws {
        try simpleStorage.addAttribute(storageType: storageType, attribute: attribute)
    }

    public func removeAttribute(attribute: String) throws {
        try simpleStorage.removeAttribute(storageType: storageType, attribute: attribute)
    }

    public func storageTypeVersion() throws -> Int {
        return try simpleStorage.storageTypeVersion(storageType: storageType)
    }

    public func setStorageTypeVersion(version: Int) throws {
        try simpleStorage.setStorageTypeVersion(storageType: storageType, version: version)
    }

    public func createOrUpdate(item: Item) throws {
        try simpleStorage.createOrUpdate(storageType: storageType, items: [item])
    }

    public func createOrUpdate(items: [Item]) throws {
        try simpleStorage.createOrUpdate(storageType: storageType, items: items)
    }

    public func find(id: UUID) throws -> Item? {
        return try simpleStorage.find(storageType: storageType, id: id)
    }

    public func find(expression: Expression = .empty) throws -> [Item] {
        return try simpleStorage.find(storageType: storageType, expression: expression)
    }

    public func count(constraints: [Constraint] = []) throws -> Int {
        return try simpleStorage.count(storageType: storageType, constraints: constraints)
    }

    public func delete(id: UUID) throws {
        try simpleStorage.delete(storageType: storageType, id: id)
    }

    public func delete(constraints: [Constraint] = []) throws {
        try simpleStorage.delete(storageType: storageType, constraints: constraints)
    }

    public static func == (lhs: SimpleStorageType, rhs: SimpleStorageType) -> Bool {
        return lhs.storageType == rhs.storageType
    }
}
