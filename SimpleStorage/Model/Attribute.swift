//
//  Attribute.swift
//  SimpleStorage
//
//  Created by Dominik Gauggel on 01.11.20.
//

import Foundation

public struct Attribute: Equatable {
    public let name: String
    public let type: AttributeType
    public let nullable: Bool

    public init(name: String, type: AttributeType, nullable: Bool = false) {
        self.name = name
        self.type = type
        self.nullable = nullable
    }

    public enum AttributeType: Equatable {
        case string
        case double
        case integer
        case uuid
        case bool
        case date
        case relationship(SimpleStorageType)
    }
}
