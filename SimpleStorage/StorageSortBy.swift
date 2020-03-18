//
//  StorageSortBy.swift
//  SimpleStorage
//
//  Created by Dominik Gauggel on 18.03.20.
//  Copyright © 2020 couchbits GmbH. All rights reserved.
//

public struct StorageSortBy {
    public let attribute: StorageType.Attribute
    public let sortOrder: SortOrder

    public enum SortOrder {
        case ascening
        case descending
    }

    public init(attribute: StorageType.Attribute, sortOrder: SortOrder) {
        self.attribute = attribute
        self.sortOrder = sortOrder
    }
}

