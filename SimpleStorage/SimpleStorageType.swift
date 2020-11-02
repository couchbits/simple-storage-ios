//
//  SimpleStorageType.swift
//  SimpleStorage
//
//  Created by Dominik Gauggel on 02.11.20.
//

import Foundation

class SimpleStorageType {
    let simpleStorage: SimpleStorage
    let storageType: String
    init(simpleStorage: SimpleStorage, storageType: String) throws {
        self.simpleStorage = simpleStorage
        self.storageType = storageType

        try simpleStorage.createStorageType(storageType: storageType)
    }

    //Schema
    public func removeStorageType() throws {
        try simpleStorage.removeStorageType(storageType: storageType)
    }

    public func addStorageTypeAttribute(attribute: Attribute) throws {
        try simpleStorage.addStorageTypeAttribute(storageType: storageType, attribute: attribute)
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

    func count(constraints: [Constraint] = []) throws -> Int {
        return try simpleStorage.count(storageType: storageType, constraints: constraints)
    }

    func delete(id: UUID) throws {
        try simpleStorage.delete(storageType: storageType, id: id)
    }

    func delete(constraints: [Constraint] = []) throws {
        try simpleStorage.delete(storageType: storageType, constraints: constraints)
    }
}
