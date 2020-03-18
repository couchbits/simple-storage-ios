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
    let sortByStringProvider: StorageSortByStringProvider
    let syncRunner: SyncRunner
    
    let schameVersionStorageTypeNameAttribute = StorageType.Attribute(name: "name", type: .text, nullable: false)
    let schemaVersionsStorageType: StorageType

    var handle: OpaquePointer?

    public convenience init(url: URL) throws {
        try self.init(url: url,
                      idProvider: DefaultIdProvider(),
                      dateProvider: DefaultDateProvider(),
                      attributeDescriptionProvider: SqliteStorageAttributeDescriptionProvider(),
                      defaultValueDescriptionProvider: SqliteStorageAttributeDefaultValueDescriptionProvider(),
                      sortByStringProvider: SqliteStorageSortByStringProvider(),
                      syncRunner: DefaultSyncRunner())
    }

    public convenience init(url: URL, idProvider: IdProvider, dateProvider: DateProvider) throws {
        try self.init(url: url,
                      idProvider: idProvider,
                      dateProvider: dateProvider,
                      attributeDescriptionProvider: SqliteStorageAttributeDescriptionProvider(),
                      defaultValueDescriptionProvider: SqliteStorageAttributeDefaultValueDescriptionProvider(),
                      sortByStringProvider: SqliteStorageSortByStringProvider(),
                      syncRunner: DefaultSyncRunner())
    }

    public convenience init(url: URL,
                            idProvider: IdProvider,
                            dateProvider: DateProvider,
                            attributeDescriptionProvider: StorageAttributeDescriptionProvider,
                            defaultValueDescriptionProvider: StorageAttributeDefaultValueDescriptionProvider,
                            sortByStringProvider: StorageSortByStringProvider) throws {
        try self.init(url: url,
              idProvider: idProvider,
              dateProvider: dateProvider,
              attributeDescriptionProvider: attributeDescriptionProvider,
              defaultValueDescriptionProvider: defaultValueDescriptionProvider,
              sortByStringProvider: sortByStringProvider,
              syncRunner: DefaultSyncRunner())
    }

    init(url: URL,
                idProvider: IdProvider,
                dateProvider: DateProvider,
                attributeDescriptionProvider: StorageAttributeDescriptionProvider,
                defaultValueDescriptionProvider: StorageAttributeDefaultValueDescriptionProvider,
                sortByStringProvider: StorageSortByStringProvider,
                syncRunner: SyncRunner) throws {
        self.idProvider = idProvider
        self.dateProvider = dateProvider
        self.attributeDescriptionProvider = attributeDescriptionProvider
        self.defaultValueDescriptionProvider = defaultValueDescriptionProvider
        self.sortByStringProvider = sortByStringProvider
        self.syncRunner = syncRunner

        schemaVersionsStorageType = StorageType(name: "storage_type_schema_version",
                                                attributes: [schameVersionStorageTypeNameAttribute,
                                                             StorageType.Attribute(name: "version", type: .integer, nullable: false)])

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

    fileprivate func performCountStatement(_ statement: OpaquePointer?) throws -> Int {
        defer {
            sqlite3_finalize(statement)
        }

        if sqlite3_step(statement) == SQLITE_ROW {
            return Int(sqlite3_column_int(statement, 0))
        }
        throw StorageError.perform(errorMessage)
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
        let metaAttributeNames = StorageType.metaAttributes.all.map { $0.name }

        for metaAttributeName in metaAttributeNames {
            guard attributes.filter({ $0.name == metaAttributeName }).isEmpty else {
                throw StorageError.invalidDefinition("\(metaAttributeName) isn't allowed!")
            }
        }
    }

    private func metaAndTypeAttributes(_ attributes: [StorageType.Attribute]) -> [StorageType.Attribute] {
        return StorageType.metaAttributes.all + attributes
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

    func buildConstraintString(_ constraint: StorageConstraint) throws -> String {
        if isNull(value: constraint.value, attribute: constraint.attribute) && constraint.attribute.nullable {
            guard constraint.contstraintOperator == .equal else { throw StorageError.invalidData("Attribute \(constraint.attribute.name) nil is only allowed with equals") }
            return "\(constraint.attribute.name) IS NULL"
        } else if isNull(value: constraint.value, attribute: constraint.attribute) {
            throw StorageError.invalidData("Attribute \(constraint.attribute.name) is nil but not nullable")
        } else {
            switch constraint.contstraintOperator {
            case .equal:
                return "\(constraint.attribute.name) = ?"
            case .greaterThan:
                try checkNumericConstraint(constraint)
                return "\(constraint.attribute.name) > ?"
            case .greaterThanOrEqual:
                try checkNumericConstraint(constraint)
                return "\(constraint.attribute.name) >= ?"
            case .lessThan:
                try checkNumericConstraint(constraint)
                return "\(constraint.attribute.name) < ?"
            case .lessThanOrEqual:
                try checkNumericConstraint(constraint)
                return "\(constraint.attribute.name) <= ?"
            }
        }
    }

    func checkNumericConstraint(_ constraint: StorageConstraint) throws {
        switch constraint.attribute.type {
        case .uuid, .string, .text, .relationship:
            throw StorageError.invalidData("Operator \(constraint.contstraintOperator) is not allowed on character fields")
        case .bool, .integer, .double, .date:
            return
        }
    }

    func buildConstraintString(constraints: [StorageConstraint]) throws -> String {
        return try constraints.map { try self.buildConstraintString($0) }.joined(separator: " AND ")
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

    func findSchemaVersion(storageType: StorageType) throws -> StorageItem? {
        return try find(storageType: schemaVersionsStorageType,
                        by: [StorageConstraint(attribute: schameVersionStorageTypeNameAttribute, value: storageType.name)]).first
    }

    func storeSchemaVersion(storageType: StorageType, version: Int) throws {
        try save(storageType: schemaVersionsStorageType, item: StorageItem(meta: findSchemaVersion(storageType: storageType)?.meta, values: [storageType.name, version]))
    }
}

extension SqliteStorage: StorageTypeCreateable {
    public func createStorageType(storageType: StorageType) throws {
        try assertAttributeNames(storageType.attributes)

        var metaAttributes = StorageType.metaAttributes.all.map(attributeDescriptionProvider.description)
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

    public func addAttribute(storageType: StorageType, attribute: StorageType.Attribute, defaultValue: Any, onSchemaVersion: Int) throws -> StorageType {
        let newStorageType = StorageType(name: storageType.name, attributes: storageType.attributes + [attribute])
        let schemaVersion = try storageTypeVersion(storageType: storageType)
        guard schemaVersion >= onSchemaVersion else { throw StorageError.migrationFailed("Cannot migrate attribute \(attribute.name) for version \(onSchemaVersion) on version \(schemaVersion)") }
        guard schemaVersion == onSchemaVersion else { return newStorageType }
        let defaultValueDescription = defaultValueDescriptionProvider.description(attribute, defaultValue: defaultValue)

        let statement = try prepareStatement(sql: "ALTER TABLE \(storageType.name) ADD COLUMN \(attributeDescriptionProvider.description(attribute)) DEFAULT \(defaultValueDescription)")

        defer {
            sqlite3_finalize(statement)
        }

        guard sqlite3_step(statement) == SQLITE_DONE else {
            throw StorageError.perform(errorMessage)
        }

        return newStorageType
    }

    public func storageTypeVersion(storageType: StorageType) throws -> Int {
        guard let schemaVersion = try findSchemaVersion(storageType: storageType) else {
            return 0
        }
        return try schemaVersion.value(index: 1)
    }

    public func incrementStorageTypeVersion(storageType: StorageType) throws {
        try storeSchemaVersion(storageType: storageType, version: storageTypeVersion(storageType: storageType) + 1)
    }

    public func removeAttribute(storageType: StorageType, attribute: StorageType.Attribute, onSchemaVersion: Int) throws -> StorageType {
        return try syncRunner.run {
            let newStorageTypeAttributes = storageType.attributes.filter { $0.name != attribute.name}
            let newStorageType = StorageType(name: storageType.name, attributes: newStorageTypeAttributes)
            let schemaVersion = try storageTypeVersion(storageType: storageType)
            guard schemaVersion >= onSchemaVersion else { throw StorageError.migrationFailed("Cannot migrate attribute \(attribute.name) for version \(onSchemaVersion) on version \(schemaVersion)") }
            guard schemaVersion == onSchemaVersion else { return newStorageType }

            try performStatement(sql: "PRAGMA foreign_keys = OFF")

            guard sqlite3_exec(handle, "BEGIN TRANSACTION", nil, nil, nil) == SQLITE_OK else {
                throw StorageError.perform(errorMessage)
            }

            do {
                let temporaryStorageType = StorageType(name: "temporary_storage_type_\(storageType.name)", attributes: newStorageTypeAttributes)
                try createStorageType(storageType: temporaryStorageType)

                let metaAndTypeAttributes = self.metaAndTypeAttributes(newStorageTypeAttributes)
                let namesString = metaAndTypeAttributes.map { $0.name }.joined(separator: ", ")

                try performStatement(sql: "INSERT INTO \(temporaryStorageType.name)(\(namesString)) SELECT \(namesString) FROM \(storageType.name)")
                try performStatement(sql: "DROP TABLE \(storageType.name)")
                try performStatement(sql: "ALTER TABLE \(temporaryStorageType.name) RENAME TO \(storageType.name)")

                guard sqlite3_exec(handle, "COMMIT TRANSACTION", nil, nil, nil) == SQLITE_OK else {
                    throw StorageError.perform(errorMessage)
                }

                try performStatement(sql: "PRAGMA foreign_keys = ON")
                return newStorageType
            } catch {
                sqlite3_exec(handle, "ROLLBACK TRANSACTION", nil, nil, nil)
                try performStatement(sql: "PRAGMA foreign_keys = ON")

                throw error
            }
        }
    }
}

extension SqliteStorage: StorageStoreable {
    @discardableResult
    public func save(storageType: StorageType, item: StorageItem) throws -> StorageItem {
        guard let item = try save(storageType: storageType, items: [item]).first else {
            throw StorageError.unexpected
        }
        return item
    }

    @discardableResult
    public func save(storageType: StorageType, items: [StorageItem]) throws -> [StorageItem] {
        return try syncRunner.run {
            let metaAndTypeAttributes = self.metaAndTypeAttributes(storageType.attributes)
            let namesString = metaAndTypeAttributes.map { $0.name }.joined(separator: ", ")

            let insertValuesString = metaAndTypeAttributes.map { _ in "?" }.joined(separator: ", ")
            let insertStatement = try prepareStatement(sql: "INSERT INTO \(storageType.name) (\(namesString)) VALUES (\(insertValuesString))")
            defer {
                sqlite3_finalize(insertStatement)
            }

            let updateValuesString = metaAndTypeAttributes.map { "\($0.name) = ?" }.joined(separator: ", ")
            let updateStatement = try prepareStatement(sql: "UPDATE \(storageType.name) SET \(updateValuesString) WHERE id = ?")
            defer {
                sqlite3_finalize(updateStatement)
            }

            guard items.filter({ $0.values.count != storageType.attributes.count}).count == 0 else {
                throw StorageError.invalidData("Attributes and values have different size")
            }

            guard sqlite3_exec(handle, "BEGIN TRANSACTION", nil, nil, nil) == SQLITE_OK else {
                throw StorageError.perform(errorMessage)
            }

            do {
                let storedItems: [StorageItem] = try items.map { item in
                    let currentDate = self.dateProvider.currentDate
                    let meta = StorageItem.Meta(id: item.meta?.id ?? idProvider.id,
                                                createdAt: item.meta?.createdAt ?? currentDate,
                                                updatedAt: currentDate)
                    let metaAndTypeValues = self.metaAndTypeValues(meta: meta, values: item.values)

                    var statement: OpaquePointer?
                    if try isNew(storageType: storageType, item: item) {
                        statement = insertStatement
                        try bindValues(attributes: metaAndTypeAttributes, values: metaAndTypeValues, statement: statement)
                    } else {
                        statement = updateStatement
                        try bindValues(attributes: metaAndTypeAttributes, values: metaAndTypeValues, statement: statement)
                        try bindUUID(meta.id, statement: statement, index: metaAndTypeAttributes.count + 1, nullable: false)
                    }

                    guard sqlite3_step(statement) == SQLITE_DONE else {
                        if #available(iOS 10.0, *) {
                            print(String(cString: sqlite3_expanded_sql(statement)))
                        } else {
                            // Fallback on earlier versions
                        }
                        throw StorageError.perform(errorMessage)
                    }

                    sqlite3_clear_bindings(statement)
                    sqlite3_reset(statement)

                    return StorageItem(meta: meta, attributes: item.values)
                }

                guard sqlite3_exec(handle, "COMMIT TRANSACTION", nil, nil, nil) == SQLITE_OK else {
                    throw StorageError.perform(errorMessage)
                }

                return storedItems
            } catch {
                sqlite3_exec(handle, "ROLLBACK TRANSACTION", nil, nil, nil)
                throw error
            }
        }
    }
}

extension SqliteStorage: StorageReadeable {
    public func all(storageType: StorageType) throws -> [StorageItem] {
        return try all(storageType: storageType, sortedBy: [])
    }

    public func all(storageType: StorageType, sortedBy: [StorageSortBy]) throws -> [StorageItem] {
        let namesString = metaAndTypeAttributes(storageType.attributes).map { $0.name }.joined(separator: ", ")
        var select = "SELECT \(namesString) FROM \(storageType.name) \(sortByStringProvider.sortByString(sortedBy))"
        let statement = try prepareStatement(sql: select)

        defer {
            sqlite3_finalize(statement)
        }

        return try read(statement: statement, storageType: storageType)
    }

    public func object(storageType: StorageType, id: UUID) throws -> StorageItem {
        guard let value = try find(storageType: storageType, by: [StorageConstraint(attribute: StorageType.metaAttributes.id, value: id)]).first else {
            throw StorageError.notFound("Object \(storageType.name) with id \(id) not found")
        }

        return value
    }

    public func find(storageType: StorageType, by constraints: [StorageConstraint]) throws -> [StorageItem] {
        return try find(storageType: storageType, by: constraints, sortedBy: [])
    }

    public func find(storageType: StorageType, by constraints: [StorageConstraint], sortedBy: [StorageSortBy]) throws -> [StorageItem] {
        let namesString = metaAndTypeAttributes(storageType.attributes).map { $0.name }.joined(separator: ", ")
        let statement = try prepareStatement(sql: "SELECT \(namesString) FROM \(storageType.name) WHERE \(buildConstraintString(constraints: constraints)) \(sortByStringProvider.sortByString(sortedBy))")

        defer {
            sqlite3_finalize(statement)
        }

        let constraintsToBind = constraints.filter { !isNull(value: $0.value, attribute: $0.attribute) }
        try bindValues(attributes: constraintsToBind.map { $0.attribute }, values: constraintsToBind.map { $0.value }, statement: statement)

        return try read(statement: statement, storageType: storageType)
    }

    public func count(storageType: StorageType) throws -> Int {
        let statement = try prepareStatement(sql: "SELECT COUNT(*) FROM \(storageType.name)")

        return try performCountStatement(statement)
    }

    public func count(storageType: StorageType, by constraints: [StorageConstraint]) throws -> Int {
        let statement = try prepareStatement(sql: "SELECT COUNT(*) FROM \(storageType.name) WHERE \(buildConstraintString(constraints: constraints))")

        let constraintsToBind = constraints.filter { !isNull(value: $0.value, attribute: $0.attribute) }
        try bindValues(attributes: constraintsToBind.map { $0.attribute }, values: constraintsToBind.map { $0.value }, statement: statement)

        return try performCountStatement(statement)
    }
}

extension SqliteStorage: StorageDeleteable {
    public func delete(storageType: StorageType, id: UUID) throws {
        try syncRunner.run {
            let statement = try prepareStatement(sql: "DELETE FROM \(storageType.name) WHERE id = ?")
            defer {
                sqlite3_finalize(statement)
            }
            try bindUUID(id, statement: statement, index: 1, nullable: false)
            try performStatement(statement: statement, finalize: false)
        }
    }

    public func delete(storageType: StorageType, ids: [UUID]) throws {
        try syncRunner.run {
            let idsTemplate = ids.map({_ in "?"}).joined(separator: ",")
            let statement = try prepareStatement(sql: "DELETE FROM \(storageType.name) WHERE id IN (\(idsTemplate))")
            defer {
                sqlite3_finalize(statement)
            }
            for (index, id) in ids.enumerated() {
                try bindUUID(id, statement: statement, index: index + 1, nullable: false)
            }
            try performStatement(statement: statement, finalize: false)
        }
    }

    public func delete(storageType: StorageType, by constraints: [StorageConstraint]) throws {
        return try syncRunner.run {
            let statement = try prepareStatement(sql: "DELETE FROM \(storageType.name) WHERE \(buildConstraintString(constraints: constraints))")

            let constraintsToBind = constraints.filter { !isNull(value: $0.value, attribute: $0.attribute) }
            try bindValues(attributes: constraintsToBind.map { $0.attribute }, values: constraintsToBind.map { $0.value }, statement: statement)

            return try performStatement(statement: statement)
        }
    }
}

fileprivate extension StorageItem {
    init(meta: StorageItem.Meta, attributes: [Any]) {
        self.meta = meta
        self.values = attributes
    }
}
