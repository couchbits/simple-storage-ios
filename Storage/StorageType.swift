//
//  StorageType.swift
//  Storage
//
//  Created by Dominik Gauggel on 11/12/19.
//  Copyright © 2019 couchbits GmbH. All rights reserved.
//
import Foundation

public struct StorageType: Equatable {
    public var name: String
    public var attributes: [Attribute]

    public struct Attribute: Equatable {
        public var name: String
        public var type: AttributeType
        public var nullable: Bool
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
