//
//  Storage.swift
//  Storage
//
//  Created by Dominik Gauggel on 11/12/19.
//  Copyright © 2019 couchbits GmbH. All rights reserved.
//

import Foundation

public protocol Storage {
    func createStorageType(storageType: StorageType) throws

    func storageTypeVersion(storageType: StorageType) throws -> Int
    func incrementStorageTypeVersion(storageType: StorageType) throws
    @discardableResult
    func addAttribute(storageType: StorageType, attribute: StorageType.Attribute, defaultValue: Any) throws -> StorageType

    @discardableResult
    func save(storageType: StorageType, item: StorageItem) throws -> StorageItem
    @discardableResult
    func save(storageType: StorageType, items: [StorageItem]) throws -> [StorageItem]

    func all(storageType: StorageType) throws -> [StorageItem]
    func object(storageType: StorageType, id: UUID) throws -> StorageItem
    func delete(storageType: StorageType, id: UUID) throws

    func find(storageType: StorageType, by constraints: [StorageConstraint]) throws -> [StorageItem]
    func delete(storageType: StorageType, by constraints: [StorageConstraint]) throws
}
