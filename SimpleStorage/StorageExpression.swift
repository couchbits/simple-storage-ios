//
//  StorageExpression.swift
//  SimpleStorage
//
//  Created by Dominik Gauggel on 18.03.20.
//  Copyright © 2020 couchbits GmbH. All rights reserved.
//

import Foundation

public struct StorageExpression: Equatable {
    public var constraints: [StorageConstraint]
    public var sortedBy: [SortBy]
    public var limit: Limit?

    public init(constraints: [StorageConstraint] = [], sortedBy: [SortBy] = [], limit: Limit? = nil) {
        self.constraints = constraints
        self.sortedBy = sortedBy
        self.limit = limit
    }

    public static var empty: StorageExpression { return StorageExpression() }

    public struct SortBy: Equatable {
        public let attribute: StorageType.Attribute
        public let sortOrder: SortOrder

        public enum SortOrder {
            case ascending
            case descending
        }

        public init(attribute: StorageType.Attribute, sortOrder: SortOrder) {
            self.attribute = attribute
            self.sortOrder = sortOrder
        }
    }

    public struct Limit: Equatable {
        public let limit: Int
        public let offset: Int?

        public init(limit: Int, offset: Int? = nil) {
            self.limit = limit
            self.offset = offset
        }
    }
}
