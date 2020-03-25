//
//  StorageSortByStringProvider.swift
//  SimpleStorage
//
//  Created by Dominik Gauggel on 18.03.20.
//  Copyright © 2020 couchbits GmbH. All rights reserved.
//

import Foundation

public protocol StorageSortByStringProvider {
    func sortByString(_ sortyBys: [StorageExpression.SortBy]) -> String


}

class SqliteStorageSortByStringProvider {
    func value(_ sortOrder: StorageExpression.SortBy.SortOrder) -> String {
        switch sortOrder {
        case .ascending:
            return "ASC"
        case .descending:
            return "DESC"
        }
    }
}
extension SqliteStorageSortByStringProvider: StorageSortByStringProvider {
    func sortByString(_ sortyBys: [StorageExpression.SortBy]) -> String {
        var sortBys = sortyBys
        if !sortyBys.contains(where: { $0.attribute.name == StorageType.metaAttributes.createdAt.name }) {
            sortBys += [StorageExpression.SortBy(attribute: StorageType.metaAttributes.createdAt, sortOrder: .ascending)]
        }
        return "ORDER BY \(sortBys.map { "\($0.attribute.name) \(value($0.sortOrder))"}.joined(separator: ", "))"
    }
}

