//
//  SimpleStorageStorageItem.swift
//  SimpleStorage
//
//  Created by Dominik Gauggel on 31.10.20.
//

import Foundation
import SQLite3

extension SimpleStorage {
    func createOrUpdate(storageType: String, item: Item) throws {
        try createOrUpdate(storageType: storageType, items: [item])
    }

    func createOrUpdate(storageType: String, items: [Item]) throws {
        try syncRunner.run {
            let tableDescription = try self.tableDescription(storageType)

            let columnsString = tableDescription.columns.map { $0.name }.joined(separator: ", ")
            let valuesString = tableDescription.columns.map { _ in "?" }.joined(separator: ", ")
            let insertStatement = try sqlite.prepareStatement(sql: "INSERT INTO \(storageType) (\(columnsString)) VALUES (\(valuesString))")

            defer {
                sqlite3_finalize(insertStatement)
            }

            let updateColumns = tableDescription
                .columns
                .filter { $0.name != "created_at"}

            let updateValuesString = updateColumns
                .map { "\($0.name) = ?" }
                .joined(separator: ", ")
            let updateStatement = try sqlite.prepareStatement(sql: "UPDATE \(storageType) SET \(updateValuesString) WHERE id = ?")

            defer {
                sqlite3_finalize(updateStatement)
            }

            try sqlite.execute(sql: "BEGIN TRANSACTION")

            do {
                for item in items {
                    let currentDate = self.dateProvider.date

                    var values = item.values
                    values["id"] = item.id
                    values["created_at"] = currentDate
                    values["updated_at"] = currentDate

                    var statement: OpaquePointer?
                    if try isNew(storageType: storageType, id: item.id) {
                        statement = insertStatement
                        try bindValues(columns: tableDescription.columns, values: values, statement: statement)
                    } else {
                        statement = updateStatement
                        try bindValues(columns: updateColumns, values: values, statement: statement)
                        bindUUID(statement: statement, index: updateColumns.count + 1, value: item.id)
                    }

                    try sqlite.performStatement(statement: statement, finalize: false)

                    sqlite3_clear_bindings(statement)
                    sqlite3_reset(statement)
                }

                try sqlite.execute(sql: "COMMIT TRANSACTION")
            } catch {
                try sqlite.execute(sql: "ROLLBACK TRANSACTION")
                throw error
            }
        }
    }

    func isNew(storageType: String, id: UUID) throws -> Bool {
        return try find(storageType: storageType, id: id) == nil
    }

    func bindValues(columns: [TableDescription.Column], values: [String: StorableDataType], statement: OpaquePointer?) throws {
        for (index, column) in columns.enumerated() {
            let index = index + 1
            if values[column.name] == nil && !column.nullable {
                throw SimpleStorageError.invalidData("\(column.name) is nil but not nilable")
            }

            if let value = values[column.name] {
                if let string = value as? String {
                    bindString(statement: statement, index: index, value: string)
                } else if let uuid = value as? UUID {
                    bindUUID(statement: statement, index: index, value: uuid)
                } else if let integer = value as? Int {
                    bindInteger(statement: statement, index: index, value: integer)
                } else if let double = value as? Double {
                    bindDouble(statement: statement, index: index, value: double)
                } else if let date = value as? Date {
                    bindDate(statement: statement, index: index, value: date)
                } else if let bool = value as? Bool {
                    bindBool(statement: statement, index: index, value: bool)
                } else {
                    throw SimpleStorageError.invalidData("Invalid type \(column.name): \(value.self)")
                }
            } else {
                sqlite3_bind_null(statement, Int32(index))
            }
        }
    }

    func bindString(statement: OpaquePointer?, index: Int, value: String) {
        sqlite3_bind_text(statement, Int32(index), NSString(string: value).utf8String, -1, nil)
    }

    func bindUUID(statement: OpaquePointer?, index: Int, value: UUID) {
        bindString(statement: statement, index: index, value: value.uuidString.lowercased())
    }

    func bindInteger(statement: OpaquePointer?, index: Int, value: Int) {
        sqlite3_bind_int64(statement, Int32(index), Int64(value))
    }

    func bindDouble(statement: OpaquePointer?, index: Int, value: Double) {
        sqlite3_bind_double(statement, Int32(index), value)
    }

    func bindBool(statement: OpaquePointer?, index: Int, value: Bool) {
        sqlite3_bind_int(statement, Int32(index), value ? 1 : 0)
    }

    func bindDate(statement: OpaquePointer?, index: Int, value: Date) {
        bindDouble(statement: statement, index: index, value: value.timeIntervalSince1970)
    }
}


