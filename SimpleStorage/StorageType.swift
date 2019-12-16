//
//  StorageType.swift
//  Storage
//
//  Created by Dominik Gauggel on 11/12/19.
//  Copyright © 2019 couchbits GmbH. All rights reserved.
//
import Foundation

public struct StorageType: Equatable {
    public let name: String
    public let attributes: [Attribute]

    public init(name: String, attributes: [Attribute]) {
        self.name = name
        self.attributes = attributes
    }

    public struct Attribute: Equatable {
        public let name: String
        public let type: AttributeType
        public let nullable: Bool

        public init(name: String, type: AttributeType, nullable: Bool) {
            self.name = name
            self.type = type
            self.nullable = nullable
        }
    }

    public enum AttributeType: Equatable {
        case uuid
        case string(Int)
        case text
        case bool
        case integer
        case double
        case date
        case relationship(String)
    }
}
