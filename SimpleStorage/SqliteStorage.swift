//
//  SqliteStorage.swift
//  Storage
//
//  Created by Dominik Gauggel on 11/12/19.
//  Copyright © 2019 couchbits GmbH. All rights reserved.
//

import Foundation
import SQLite3

public class SqliteStorage {
    let idProvider: IdProvider
    let dateProvider: DateProvider
    let attributeDescriptionProvider: StorageAttributeDescriptionProvider
    let defaultValueDescriptionProvider: StorageAttributeDefaultValueDescriptionProvider

    let idAttribute = StorageType.Attribute(name: "id", type: .uuid, nullable: false)
    let metaAttributes: [StorageType.Attribute]

    let schameVersionStorageTypeNameAttribute = StorageType.Attribute(name: "name", type: .text, nullable: false)
    let schemaVersionsStorageType: StorageType

    var handle: OpaquePointer?

    public convenience init(url: URL) throws {
        try self.init(url: url,
                  idProvider: DefaultIdProvider(),
                  dateProvider: DefaultDateProvider(),
                  attributeDescriptionProvider: SqliteStorageAttributeDescriptionProvider(),
                  defaultValueDescriptionProvider: SqliteStorageAttributeDefaultValueDescriptionProvider())
    }

    public convenience init(url: URL, idProvider: IdProvider, dateProvider: DateProvider) throws {
        try self.init(url: url,
                  idProvider: idProvider,
                  dateProvider: dateProvider,
                  attributeDescriptionProvider: SqliteStorageAttributeDescriptionProvider(),
                  defaultValueDescriptionProvider: SqliteStorageAttributeDefaultValueDescriptionProvider())
    }

    public init(url: URL,
                idProvider: IdProvider,
                dateProvider: DateProvider,
                attributeDescriptionProvider: StorageAttributeDescriptionProvider,
                defaultValueDescriptionProvider: StorageAttributeDefaultValueDescriptionProvider) throws {
        self.idProvider = idProvider
        self.dateProvider = dateProvider
        self.attributeDescriptionProvider = attributeDescriptionProvider
        self.defaultValueDescriptionProvider = defaultValueDescriptionProvider

        schemaVersionsStorageType = StorageType(name: "storage_type_schema_version",
                                                attributes: [schameVersionStorageTypeNameAttribute,
                                                             StorageType.Attribute(name: "version", type: .integer, nullable: false)])

        metaAttributes = [idAttribute,
                          StorageType.Attribute(name: "createdAt", type: .date, nullable: false),
                          StorageType.Attribute(name: "updatedAt", type: .date, nullable: false)]

        let flags = SQLITE_OPEN_CREATE | SQLITE_OPEN_READWRITE | SQLITE_OPEN_FULLMUTEX
        guard sqlite3_open_v2(url.absoluteString, &handle, flags, nil) == SQLITE_OK else {
            throw StorageError.open(errorMessage)
        }
        try performStatement(sql: "PRAGMA foreign_keys = ON")

        try createStorageType(storageType: schemaVersionsStorageType)
    }

    deinit {
        sqlite3_close(handle)
    }

    private func read(statement: OpaquePointer?, storageType: StorageType) throws -> [StorageItem] {
        var rows = [StorageItem]()

        while sqlite3_step(statement) == SQLITE_ROW {
            var row = [Any]()
            for (index, attribute) in metaAndTypeAttributes(storageType.attributes).enumerated() {
                switch attribute.type {
                case .uuid, .relationship:
                    row.append(try readUUID(statement: statement, index: index, nullable: attribute.nullable) as Any)
                case .string, .text:
                    row.append(try readString(statement: statement, index: index, nullable: attribute.nullable) as Any)
                case .bool:
                    row.append(try readBool(statement: statement, index: index, nullable: attribute.nullable) as Any)
                case .integer:
                    row.append(try readInt(statement: statement, index: index, nullable: attribute.nullable) as Any)
                case .double:
                    row.append(try readDouble(statement: statement, index: index, nullable: attribute.nullable) as Any)
                case .date:
                    row.append(try readDate(statement: statement, index: index, nullable: attribute.nullable) as Any)
                }
            }

            rows.append(StorageItem(meta: StorageItem.Meta(id: try value(row[0]), createdAt: try value(row[1]), updatedAt: try value(row[2])), attributes: Array(row.suffix(from: 3))))
        }

        return rows
    }

    private func value<T>(_ value: Any) throws -> T {
        guard let castedValue = value as? T else {
            throw StorageError.invalidData("Value \(value) isn't of type \(T.self)")
        }
        return castedValue
    }

    private func prepareStatement(sql: String) throws -> OpaquePointer? {
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(handle, sql, -1, &statement, nil) == SQLITE_OK else {
            throw StorageError.prepareStatement(errorMessage)
        }

        return statement
    }

    private func performStatement(sql: String) throws {
        try performStatement(statement: try prepareStatement(sql: sql))
    }

    private func performStatement(statement: OpaquePointer?, finalize: Bool = true) throws {
        defer {
            if finalize {
                sqlite3_finalize(statement)
            }
        }
        guard sqlite3_step(statement) == SQLITE_DONE else {
            throw StorageError.perform(errorMessage)
        }
    }

    private var errorMessage: String {
        if let errorPointer = sqlite3_errmsg(handle) {
            let errorMessage = String(cString: errorPointer)
            return errorMessage
        } else {
            return "No error message provided from sqlite."
        }
    }

    private func assertAttributeNames(_ attributes: [StorageType.Attribute]) throws {
        let metaAttributeNames = metaAttributes.map { $0.name }

        for metaAttributeName in metaAttributeNames {
            guard attributes.filter({ $0.name == metaAttributeName }).isEmpty else {
                throw StorageError.invalidDefinition("\(metaAttributeName) isn't allowed!")
            }
        }
    }

    private func metaAndTypeAttributes(_ attributes: [StorageType.Attribute]) -> [StorageType.Attribute] {
        return metaAttributes + attributes
    }

    private func metaAndTypeValues(meta: StorageItem.Meta, values: [Any]) -> [Any] {
        return [meta.id, meta.createdAt, meta.updatedAt] + values
    }

    private func createMeta() -> StorageItem.Meta {
        return StorageItem.Meta(id: idProvider.id, createdAt: dateProvider.currentDate, updatedAt: dateProvider.currentDate)
    }

    private func map(_ date: Date) -> Double {
        return date.timeIntervalSince1970
    }

    private func map(_ timeInterval: Double) -> Date {
        return Date(timeIntervalSince1970: timeInterval)
    }

    func readUUID(statement: OpaquePointer?, index: Int, nullable: Bool) throws -> UUID? {
        if let value = try readString(statement: statement, index: index, nullable: nullable) {
            return UUID(uuidString: value)
        } else if nullable {
            return nil
        } else {
            throw StorageError.invalidData("Value is null or not an UUID")
        }
    }

    func readString(statement: OpaquePointer?, index: Int, nullable: Bool) throws -> String? {
        let columnType = sqlite3_column_type(statement, Int32(index))
        if columnType == SQLITE_TEXT {
            return String(cString: sqlite3_column_text(statement, Int32(index)))
        } else if nullable && columnType == SQLITE_NULL {
            return nil
        } else {
            throw StorageError.invalidData("Value is null or not a string")
        }
    }

    func readDouble(statement: OpaquePointer?, index: Int, nullable: Bool) throws -> Double? {
        let columnType = sqlite3_column_type(statement, Int32(index))
        if columnType == SQLITE_FLOAT {
            return sqlite3_column_double(statement, Int32(index))
        } else if nullable && columnType == SQLITE_NULL {
            return nil
        } else {
            throw StorageError.invalidData("Value is null or a double")
        }
    }

    func readInt(statement: OpaquePointer?, index: Int, nullable: Bool) throws -> Int? {
        let columnType = sqlite3_column_type(statement, Int32(index))
        if columnType == SQLITE_INTEGER {
            return Int(sqlite3_column_int64(statement, Int32(index)))
        } else if nullable && columnType == SQLITE_NULL {
            return nil
        } else {
            throw StorageError.invalidData("Value is null or not an integer")
        }
    }

    func readBool(statement: OpaquePointer?, index: Int, nullable: Bool) throws -> Bool? {
        if let value = try readInt(statement: statement, index: index, nullable: nullable) {
            return value > 0
        } else if nullable {
            return nil
        } else {
            throw StorageError.invalidData("Value is null or not a bool")
        }
    }

    func readDate(statement: OpaquePointer?, index: Int, nullable: Bool) throws -> Date? {
        if let value = try readDouble(statement: statement, index: index, nullable: nullable) {
            return Date(timeIntervalSince1970: value)
        } else if nullable {
            return nil
        } else {
            throw StorageError.invalidData("Value is null or not a bool")
        }
    }

    func bindUUID(_ value: UUID?, statement: OpaquePointer?, index: Int, nullable: Bool) throws {
        try bindString(value?.idString, statement: statement, index: index, nullable: nullable)
    }

    func bindString(_ value: String?, statement: OpaquePointer?, index: Int, nullable: Bool) throws {
        if let value = value {
            sqlite3_bind_text(statement, Int32(index), NSString(string: value).utf8String, -1, nil)
        } else if nullable {
            sqlite3_bind_null(statement, Int32(index))
        } else {
            throw StorageError.invalidData("Value is null, but nullable is not allowed")
        }
    }

    func bindDouble(_ value: Double?, statement: OpaquePointer?, index: Int, nullable: Bool) throws {
        if let value = value {
            sqlite3_bind_double(statement, Int32(index), value)
        } else if nullable {
            sqlite3_bind_null(statement, Int32(index))
        } else {
            throw StorageError.invalidData("Value is null, but nullable is not allowed")
        }
    }

    func bindDate(_ value: Date?, statement: OpaquePointer?, index: Int, nullable: Bool) throws {
        try bindDouble(value?.timeIntervalSince1970, statement: statement, index: index, nullable: nullable)
    }

    func bindInt(_ value: Int?, statement: OpaquePointer?, index: Int, nullable: Bool) throws {
        if let value = value {
            sqlite3_bind_int64(statement, Int32(index), Int64(value))
        } else if nullable {
            sqlite3_bind_null(statement, Int32(index))
        } else {
            throw StorageError.invalidData("Value is null, but nullable is not allowed")
        }
    }

    func bindBool(_ value: Bool?, statement: OpaquePointer?, index: Int, nullable: Bool) throws {
        if let value = value {
            try bindInt(value ? 1 : 0, statement: statement, index: index, nullable: nullable)
        } else {
            try bindInt(nil, statement: statement, index: index, nullable: nullable)
        }
    }

    func isNew(storageType: StorageType, item: StorageItem) throws -> Bool {
        guard let meta = item.meta else {
            return true
        }

        do {
            _ = try object(storageType: storageType, id: meta.id)
            return false
        } catch StorageError.notFound {
            return true
        }
    }

    func bindValues(attributes: [StorageType.Attribute], values: [Any], statement: OpaquePointer?) throws {
        for (index, attribute) in attributes.enumerated() {
            let statementIndex = index + 1
            switch attribute.type {
            case .uuid, .relationship:
                try bindUUID(try value(values[index]), statement: statement, index: statementIndex, nullable: attribute.nullable)
            case .string, .text:
                try bindString(try value(values[index]), statement: statement, index: statementIndex, nullable: attribute.nullable)
            case .bool:
                try bindBool(try self.value(values[index]), statement: statement, index: statementIndex, nullable: attribute.nullable)
            case .integer:
                try bindInt(try self.value(values[index]), statement: statement, index: statementIndex, nullable: attribute.nullable)
            case .double:
                try bindDouble(try self.value(values[index]), statement: statement, index: statementIndex, nullable: attribute.nullable)
            case .date:
                try bindDate(try self.value(values[index]), statement: statement, index: statementIndex, nullable: attribute.nullable)
            }
        }
    }

    func constraintString(_ constraint: StorageConstraint) throws -> String {
        if isNull(value: constraint.value, attribute: constraint.attribute) && constraint.attribute.nullable {
            return "\(constraint.attribute.name) IS NULL"
        } else if isNull(value: constraint.value, attribute: constraint.attribute) {
            throw StorageError.invalidData("Attribute \(constraint.attribute.name) is nil but not nullable")
        } else {
            return "\(constraint.attribute.name) = ?"
        }
    }

    func isNull(value: Any, attribute: StorageType.Attribute) -> Bool {
        switch attribute.type {
        case .uuid, .relationship:
            return value as? UUID == nil
        case .string, .text:
            return value as? String == nil
        case .bool:
            return value as? Bool == nil
        case .integer:
            return value as? Int == nil
        case .double:
            return value as? Double == nil
        case .date:
            return value as? Date == nil
        }
    }

    func storeSchemaVersion(storageType: StorageType, version: Int) throws {
        try save(storageType: schemaVersionsStorageType, item: StorageItem(values: [storageType.name, version]))
    }
}

extension SqliteStorage: Storage {
    public func createStorageType(storageType: StorageType) throws {
        try assertAttributeNames(storageType.attributes)

        var metaAttributes = self.metaAttributes.map(attributeDescriptionProvider.description)
        if let idAttribute = metaAttributes.first {
            metaAttributes[0] = "\(idAttribute) PRIMARY KEY"
        }
        let attributes = (metaAttributes + storageType.attributes.map(attributeDescriptionProvider.description)).joined(separator: ", ")
        let statement = "CREATE TABLE IF NOT EXISTS \(storageType.name)(\(attributes))"

        let createTableStatement = try prepareStatement(sql: statement)

        defer {
            sqlite3_finalize(createTableStatement)
        }

        guard sqlite3_step(createTableStatement) == SQLITE_DONE else {
            throw StorageError.perform(errorMessage)
        }
    }

    public func addAttribute(storageType: StorageType, attribute: StorageType.Attribute, defaultValue: Any) throws -> StorageType {
        let defaultValueDescription = defaultValueDescriptionProvider.description(attribute, defaultValue: defaultValue)

        let statement = try prepareStatement(sql: "ALTER TABLE \(storageType.name) ADD COLUMN \(attributeDescriptionProvider.description(attribute)) DEFAULT \(defaultValueDescription)")

        defer {
            sqlite3_finalize(statement)
        }

        guard sqlite3_step(statement) == SQLITE_DONE else {
            throw StorageError.perform(errorMessage)
        }

        return StorageType(name: storageType.name, attributes: storageType.attributes + [attribute])
    }

    public func storageTypeVersion(storageType: StorageType) throws -> Int {
        guard let schemaVersion = try find(storageType: schemaVersionsStorageType,
                                           by: [StorageConstraint(attribute: schameVersionStorageTypeNameAttribute, value: storageType.name)]).first else {
            return 0
        }
        return try schemaVersion.value(index: 1)
    }

    public func incrementStorageTypeVersion(storageType: StorageType) throws {
        try storeSchemaVersion(storageType: storageType, version: storageTypeVersion(storageType: storageType) + 1)
    }

    @discardableResult
    public func save(storageType: StorageType, item: StorageItem) throws -> StorageItem {
        guard storageType.attributes.count == item.values.count else {
            throw StorageError.invalidData("Attributes and values have different size")
        }

        let currentDate = dateProvider.currentDate
        let meta = StorageItem.Meta(id: item.meta?.id ?? idProvider.id,
                                    createdAt: item.meta?.createdAt ?? currentDate,
                                    updatedAt: currentDate)

        let metaAndTypeAttributes = self.metaAndTypeAttributes(storageType.attributes)
        let namesString = metaAndTypeAttributes.map { $0.name }.joined(separator: ", ")
        let metaAndTypeValues = self.metaAndTypeValues(meta: meta, values: item.values)

        let statement: OpaquePointer?
        if try isNew(storageType: storageType, item: item) {
            let valuesString = metaAndTypeValues.map { _ in "?" }.joined(separator: ", ")
            statement = try prepareStatement(sql: "INSERT INTO \(storageType.name) (\(namesString)) VALUES (\(valuesString))")
        } else {
            let valuesString = metaAndTypeAttributes.map { "\($0.name) = ?" }.joined(separator: ", ")
            statement = try prepareStatement(sql: "UPDATE \(storageType.name) SET \(valuesString) WHERE id = ?")
            try bindUUID(meta.id, statement: statement, index: metaAndTypeAttributes.count + 1, nullable: false)
        }

        defer {
            sqlite3_finalize(statement)
        }

        try bindValues(attributes: metaAndTypeAttributes, values: metaAndTypeValues, statement: statement)

        guard sqlite3_step(statement) == SQLITE_DONE else {
            if #available(iOS 10.0, *) {
                print(String(cString: sqlite3_expanded_sql(statement)))
            } else {
                // Fallback on earlier versions
            }
            throw StorageError.perform(errorMessage)
        }

        return StorageItem(meta: meta, attributes: item.values)
    }

    public func all(storageType: StorageType) throws -> [StorageItem] {
        let namesString = metaAndTypeAttributes(storageType.attributes).map { $0.name }.joined(separator: ", ")
        var select = "SELECT \(namesString) FROM \(storageType.name)"
        let statement = try prepareStatement(sql: select)

        defer {
            sqlite3_finalize(statement)
        }

        return try read(statement: statement, storageType: storageType)
    }

    public func object(storageType: StorageType, id: UUID) throws -> StorageItem {
        guard let value = try find(storageType: storageType, by: [StorageConstraint(attribute: idAttribute, value: id)]).first else {
            throw StorageError.notFound("Object \(storageType.name) with id \(id) not found")
        }

        return value
    }

    public func delete(storageType: StorageType, id: UUID) throws {
        let statement = try prepareStatement(sql: "DELETE FROM \(storageType.name) WHERE id = ?")
        defer {
            sqlite3_finalize(statement)
        }
        try bindUUID(id, statement: statement, index: 1, nullable: false)
        try performStatement(statement: statement, finalize: false)
    }

    public func find(storageType: StorageType, by constraints: [StorageConstraint]) throws -> [StorageItem] {
        let namesString = metaAndTypeAttributes(storageType.attributes).map { $0.name }.joined(separator: ", ")
        let constraintString = try constraints.map { try self.constraintString($0) }.joined(separator: " AND ")
        let statement = try prepareStatement(sql: "SELECT \(namesString) FROM \(storageType.name) WHERE \(constraintString)")

        let constraintsToBind = constraints.filter { !isNull(value: $0.value, attribute: $0.attribute) }
        try bindValues(attributes: constraintsToBind.map { $0.attribute }, values: constraintsToBind.map { $0.value }, statement: statement)

        return try read(statement: statement, storageType: storageType)
    }

    public func delete(storageType: StorageType, by constraints: [StorageConstraint]) throws {
        let constraintString = try constraints.map { try self.constraintString($0) }.joined(separator: " AND ")
        let statement = try prepareStatement(sql: "DELETE FROM \(storageType.name) WHERE \(constraintString)")

        let constraintsToBind = constraints.filter { !isNull(value: $0.value, attribute: $0.attribute) }
        try bindValues(attributes: constraintsToBind.map { $0.attribute }, values: constraintsToBind.map { $0.value }, statement: statement)

        return try performStatement(statement: statement)
    }
}

fileprivate extension StorageItem {
    init(meta: StorageItem.Meta, attributes: [Any]) {
        self.meta = meta
        self.values = attributes
    }
}
