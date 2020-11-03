//
//  TestUtils.swift
//  SimpleStorageTests
//
//  Created by Dominik Gauggel on 01.11.20.
//

import Foundation
@testable import SimpleStorage
import SQLite3

class TestUtils {
    static func createStorageType(sut: SimpleStorage, nullable: Bool = false) throws -> SimpleStorageType {
        //prepare
        let storageType = try SimpleStorageType(simpleStorage: sut, storageType: "mytype")
        try storageType.addAttribute(
            attribute: Attribute(name: "myinteger", type: .integer, nullable: nullable)
        )
        try storageType.addAttribute(
            attribute: Attribute(name: "mystring", type: .string, nullable: nullable)
        )
        try storageType.addAttribute(
            attribute: Attribute(name: "mydouble", type: .double, nullable: nullable)
        )
        try storageType.addAttribute(
            attribute: Attribute(name: "mybool", type: .bool, nullable: nullable)
        )
        try storageType.addAttribute(
            attribute: Attribute(name: "myuuid", type: .uuid, nullable: nullable)
        )
        try storageType.addAttribute(
            attribute: Attribute(name: "mydate", type: .date, nullable: nullable)
        )

        return storageType
    }

    static func createItem() -> Item {
        return Item(
            id: UUID(),
            values: [
                "myinteger": 42,
                "mystring": "any-string",
                "mydouble": 123.45,
                "mybool": true,
                "myuuid": UUID(),
                "mydate": Date(timeIntervalSince1970: 420)
            ]
        )
    }

    static func count(sut: SimpleStorage, storageType: String, whereClause: String? = nil) throws -> Int {
        var statement: OpaquePointer?

        defer {
            sqlite3_finalize(statement)
        }

        var select = "SELECT count(*) FROM \(storageType)"
        if let whereClause = whereClause {
            select += " WHERE \(whereClause)"
        }
        select += ";"

        if sqlite3_prepare_v2(sut.sqlite.handle, select, -1, &statement, nil) == SQLITE_OK {
            if sqlite3_step(statement) == SQLITE_ROW {
                return Int(sqlite3_column_int(statement, 0))
            }
        }
        throw SimpleStorageError.unexpected
    }
}
