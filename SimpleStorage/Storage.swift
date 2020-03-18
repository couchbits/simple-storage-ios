//
//  Storage.swift
//  Storage
//
//  Created by Dominik Gauggel on 11/12/19.
//  Copyright © 2019 couchbits GmbH. All rights reserved.
//

import Foundation

public protocol StorageTypeCreateable {
    func createStorageType(storageType: StorageType) throws
    func storageTypeVersion(storageType: StorageType) throws -> Int
    func incrementStorageTypeVersion(storageType: StorageType) throws
    @discardableResult
    func addAttribute(storageType: StorageType, attribute: StorageType.Attribute, defaultValue: Any, onSchemaVersion: Int) throws -> StorageType
    func removeAttribute(storageType: StorageType, attribute: StorageType.Attribute, onSchemaVersion: Int) throws -> StorageType
}

public protocol StorageStoreable {
    @discardableResult
    func save(storageType: StorageType, item: StorageItem) throws -> StorageItem
    @discardableResult
    func save(storageType: StorageType, items: [StorageItem]) throws -> [StorageItem]
}

public protocol StorageReadeable {
    func object(storageType: StorageType, id: UUID) throws -> StorageItem
    
    func all(storageType: StorageType) throws -> [StorageItem]
    func find(storageType: StorageType, expression: StorageExpression) throws -> [StorageItem]
    func count(storageType: StorageType) throws -> Int
    func count(storageType: StorageType, by constraints: [StorageConstraint]) throws -> Int
}

public protocol StorageDeleteable {
    func delete(storageType: StorageType, id: UUID) throws
    func delete(storageType: StorageType, ids: [UUID]) throws
    func delete(storageType: StorageType, by constraints: [StorageConstraint]) throws
}

public typealias Storage = StorageTypeCreateable & StorageStoreable & StorageReadeable & StorageDeleteable
