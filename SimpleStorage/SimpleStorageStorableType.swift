//
//  SimpleStorageStorableType.swift
//  SimpleStorage
//
//  Created by Dominik Gauggel on 02.11.20.
//

import Foundation

public protocol SimpleStorageStorableType {
    static func map(_ item: Item) throws -> Self
    static func map(_ storableType: Self) throws -> Item
}

extension SimpleStorageType {
    public func createOrUpdate<T: SimpleStorageStorableType>(storableType: T) throws {
        try createOrUpdate(items: [T.map(storableType)])
    }

    public func createOrUpdate<T: SimpleStorageStorableType>(storableTypes: [T]) throws {
        try createOrUpdate(items: storableTypes.map(T.map))
    }

    public func find<T: SimpleStorageStorableType>(id: UUID) throws -> T? {
        guard let item = try find(id: id) else { return nil }
        return try T.map(item)
    }

    public func find<T: SimpleStorageStorableType>(expression: Expression = .empty) throws -> [T] {
        return try find(expression: expression).map(T.map)
    }
}
