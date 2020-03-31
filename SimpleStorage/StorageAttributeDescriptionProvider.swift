//
//  AttributeDescriptionProvider.swift
//  Storage
//
//  Created by Dominik Gauggel on 11/12/19.
//  Copyright © 2019 couchbits GmbH. All rights reserved.
//

import Foundation

protocol StorageAttributeDescriptionProvider {
    func description(_ attribute: StorageType.Attribute) -> String
}

//swiftlint:disable:next type_name
class SqliteStorageAttributeDescriptionProvider {}

extension SqliteStorageAttributeDescriptionProvider: StorageAttributeDescriptionProvider {
    func description(_ attribute: StorageType.Attribute) -> String {
        var statement = "\(attribute.name) \(type(attribute.type))"


        if attribute.nullable {
            statement = "\(statement) NULL"
        } else {
            statement = "\(statement) NOT NULL"
        }

        if case let .relationship(storageTypeName) = attribute.type {
            if attribute.nullable {
                statement = "\(statement) REFERENCES \(storageTypeName)(id) ON UPDATE SET NULL ON DELETE SET NULL"
            } else {
                 statement = "\(statement) REFERENCES \(storageTypeName)(id) ON UPDATE CASCADE ON DELETE CASCADE"
            }
        }

        return statement
    }

    private func type(_ attributeType: StorageType.AttributeType) -> String {
        switch attributeType {
        case .uuid, .relationship:
            return "VARCHAR(37)"
        case .string(let length):
            return "VARCHAR(\(length))"
        case .text:
            return "TEXT"
        case .bool:
            return "INT(1)"
        case .integer:
            return "INT"
        case .double:
            return "DOUBLE"
        case .date:
            return "DOUBLE"
        }
    }
}
