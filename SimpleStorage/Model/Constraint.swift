//
//  Constraint.swift
//  SimpleStorage
//
//  Created by Dominik Gauggel on 01.11.20.
//

import Foundation

public struct Constraint: Equatable {
    public var attribute: String
    public var value: StorableType?
    public var `operator`: Operator

    public init(attribute: String, value: StorableType?, operator: Operator = .equal) {
        self.attribute = attribute
        self.value = value
        self.operator = `operator`
    }

    public static func == (lhs: Constraint, rhs: Constraint) -> Bool {
        return lhs.attribute == rhs.attribute
    }

    public enum Operator: Equatable {
        case equal
        case notEqual
        case greaterThan
        case greaterThanOrEqual
        case lessThan
        case lessThanOrEqual
    }
}
