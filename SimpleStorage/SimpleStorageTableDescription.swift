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
        if isText(type: type) {
            return .text
        } else if isInteger(type: type) {
            return .integer
        } else if isReal(type: type) {
            return .real
        } else {
            throw SimpleStorageError.invalidDefinition("Invalid type definition: \(type)")
        }
    }
    
    func isText(type: String) -> Bool {
        return type == "TEXT" || type.starts(with: "VARCHAR")
    }
    
    func isInteger(type: String) -> Bool {
        return type == "INTEGER" || type == "NUMERIC" || type.starts(with: "INT")
    }
    
    func isReal(type: String) -> Bool {
        return type == "REAL" || type == "DOUBLE"
    }
}
