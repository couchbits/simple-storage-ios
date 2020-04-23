//
//  StorageAttributeDefaultValueDescriptionProvider.swift
//  Storage
//
//  Created by Dominik Gauggel on 11/12/19.
//  Copyright © 2019 couchbits GmbH. All rights reserved.
//

import Foundation

protocol StorageAttributeDefaultValueDescriptionProvider {
    func description(_ attribute: StorageType.Attribute, defaultValue: StorageStorableType?) -> String
}

class SqliteStorageAttributeDefaultValueDescriptionProvider {}

extension SqliteStorageAttributeDefaultValueDescriptionProvider: StorageAttributeDefaultValueDescriptionProvider {
    func description(_ attribute: StorageType.Attribute, defaultValue: StorageStorableType?) -> String {
        guard let defaultValue = defaultValue else { return "NULL" }
        switch attribute.type {
        case .uuid:
            if let value = defaultValue as? UUID {
                return "'\(value.uuidString)'"
            }
        case .string(_), .text:
            if let value = defaultValue as? String {
                return "'\(value)'"
            }
        case .bool:
            if let value = defaultValue as? Bool {
                return value ? "1" : "0"
            }
        case .integer:
            if let value = defaultValue as? Int {
                return "'\(value)'"
            } else if let value = defaultValue as? Double {
                return "'\(Int(value))'"
            }
        case .double:
            if let value = defaultValue as? Double {
                return "'\(value)'"
            } else if let value = defaultValue as? Int {
                return "'\(value)'"
            }
        case .date:
            if let value = defaultValue as? Date {
                return "\(value.timeIntervalSince1970)"
            }
        case .relationship(_):
            if let value = defaultValue as? UUID {
                return "'\(value.uuidString)'"
            }
        }
        return "NULL"
    }
}
