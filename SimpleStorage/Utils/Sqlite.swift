//
//  Sqlite.swift
//  SimpleStorage
//
//  Created by Dominik Gauggel on 30.10.20.
//

import Foundation
import SQLite3

class Sqlite {
    var handle: OpaquePointer?
    var printSql: Bool

    init(path: String, printSql: Bool) throws {
        self.printSql = printSql

        let flags = SQLITE_OPEN_CREATE | SQLITE_OPEN_READWRITE | SQLITE_OPEN_FULLMUTEX | SQLITE_OPEN_FILEPROTECTION_NONE
        guard sqlite3_open_v2(path, &handle, flags, nil) == SQLITE_OK else {
            throw SimpleStorageError.open(errorMessage)
        }

        try performStatement(sql: "PRAGMA foreign_keys = ON")
        try performStatement(sql: "VACUUM")
    }

    func prepareStatement(sql: String) throws -> OpaquePointer? {
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(handle, sql, -1, &statement, nil) == SQLITE_OK else {
            throw SimpleStorageError.prepareStatement(errorMessage)
        }

        return statement
    }

    func performStatement(sql: String) throws {
        try performStatement(statement: try prepareStatement(sql: sql))
    }

    func performStatement(statement: OpaquePointer?, finalize: Bool = true) throws {
        defer {
            if finalize {
                sqlite3_finalize(statement)
            }
        }

        print(statement: statement)

        guard sqlite3_step(statement) == SQLITE_DONE else {
            throw SimpleStorageError.perform(errorMessage)
        }
    }

    func performCountStatement(_ statement: OpaquePointer?) throws -> Int {
        defer {
            sqlite3_finalize(statement)
        }

        print(statement: statement)

        guard sqlite3_step(statement) == SQLITE_ROW else {
            throw SimpleStorageError.perform(errorMessage)
        }
        return Int(sqlite3_column_int(statement, 0))
    }

    func execute(sql: String) throws {
        if printSql { NSLog(sql) }

        guard sqlite3_exec(handle, sql, nil, nil, nil) == SQLITE_OK else {
            throw SimpleStorageError.perform(errorMessage)
        }
    }

    private func print(statement: OpaquePointer?) {
        if printSql {
            if #available(iOS 10.0, *) {
                NSLog(String(cString: sqlite3_expanded_sql(statement)))
            }
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
}
