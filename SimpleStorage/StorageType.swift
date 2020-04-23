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

    public static let metaAttributes = MetaAttributes()

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

    public struct MetaAttributes: Equatable {
        public let id: StorageType.Attribute
        public let createdAt: StorageType.Attribute
        public let updatedAt: StorageType.Attribute
        public let all: [StorageType.Attribute]

        init() {
            id = StorageType.Attribute(name: "id", type: .uuid, nullable: false)
            createdAt = StorageType.Attribute(name: "createdAt", type: .date, nullable: false)
            updatedAt = StorageType.Attribute(name: "updatedAt", type: .date, nullable: false)
            all = [id, createdAt, updatedAt]
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
