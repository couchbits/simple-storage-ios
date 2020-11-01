//
//  SimpleStorageTableDescription.swift
//  SimpleStorage
//
//  Created by Dominik Gauggel on 31.10.20.
//

import Foundation
import SQLite3

extension SimpleStorage {
    func tableDescription(_ storageType: String) throws -> TableDescription {
        let statement = try sqlite.prepareStatement(sql: "PRAGMA table_info(\(storageType))")

        var columns = [TableDescription.Column]()
        while sqlite3_step(statement) == SQLITE_ROW {
            columns.append(
                TableDescription.Column(
                    name: String(cString: sqlite3_column_text(statement, 1)),
                    type: try mapType(String(cString: sqlite3_column_text(statement, 2))),
                    nullable: Int(sqlite3_column_int64(statement, 3)) == 0
                )
            )
        }

        return TableDescription(name: storageType, columns: columns)
    }

    func mapType(_ type: String) throws -> TableDescription.Column.ColumnType {
        switch type {
        case "TEXT":
            return .text
        case "INTEGER":
            return .integer
        case "NUMERIC":
            return .integer
        case "REAL":
            return .real
        default:
            throw SimpleStorageError.invalidDefinition("Invalid type definition: \(type)")
        }
    }
}
