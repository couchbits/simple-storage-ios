//
//  Expression.swift
//  SimpleStorage
//
//  Created by Dominik Gauggel on 01.11.20.
//

import Foundation

public struct Expression: Equatable {
    public var constraints: [Constraint]
    public var sortedBy: [SortBy]
    public var limit: Limit?

    public init(constraints: [Constraint] = [], sortedBy: [SortBy] = [], limit: Limit? = nil) {
        self.constraints = constraints
        self.sortedBy = sortedBy
        self.limit = limit
    }

    public static var empty: Expression { return Expression() }

    public struct SortBy: Equatable {
        public let attribute: String
        public let sortOrder: SortOrder

        public enum SortOrder {
            case ascending
            case descending
        }

        public init(attribute: String, sortOrder: SortOrder) {
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
