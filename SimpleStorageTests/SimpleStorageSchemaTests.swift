//
//  SimpleStorageTests.swift
//  SimpleStorageTestsa
//
//  Created by Dominik Gauggel on 30.10.20.
//

import XCTest
import SQLite3
@testable import SimpleStorage

class SimpleStorageTests: XCTestCase {
    var sut: SimpleStorage!

    override func setUp() {
        super.setUp()

        sut = try! SimpleStorage(configuration: .defaultInMemory)
    }

    func test_createStorageType_shouldCreateTheStorageType() throws {
        //execute
        _ = try SimpleStorageType(simpleStorage: sut, storageType: "mytype")

        //verify
        let tableDescription = try table("mytype")
        XCTAssertEqual(tableDescription[0], TableColumn(name: "id", type: "TEXT", notNull: true))
        XCTAssertEqual(tableDescription[1], TableColumn(name: "created_at", type: "REAL", notNull: true))
        XCTAssertEqual(tableDescription[2], TableColumn(name: "updated_at", type: "REAL", notNull: true))
    }

    func test_createAttribute_shouldAddStringAttribute() throws {
        //prepare
        let storageType = try SimpleStorageType(simpleStorage: sut, storageType: "mytype")

        //execute
        try storageType.addStorageTypeAttribute(attribute: Attribute(name: "myvalue", type: .string, nullable: false))

        //verify
        XCTAssertEqual(try table("mytype").last, TableColumn(name: "myvalue", type: "TEXT", notNull: true))
    }

    func test_createAttribute_shouldAddStringAttribute_Nullable() throws {
        //prepare
        let storageType = try SimpleStorageType(simpleStorage: sut, storageType: "mytype")

        //execute
        try storageType.addStorageTypeAttribute(attribute: Attribute(name: "myvalue", type: .string, nullable: true))

        //verify
        XCTAssertEqual(try table("mytype").last, TableColumn(name: "myvalue", type: "TEXT", notNull: false))
    }

    func test_createAttribute_shouldAddUUIDAttribute() throws {
        //prepare
        let storageType = try SimpleStorageType(simpleStorage: sut, storageType: "mytype")

        //execute
        try storageType.addStorageTypeAttribute(attribute: Attribute(name: "myvalue", type: .uuid, nullable: false))

        //verify
        XCTAssertEqual(try table("mytype").last, TableColumn(name: "myvalue", type: "TEXT", notNull: true))
    }

    func test_createAttribute_shouldAddUUIDAttribute_Nullable() throws {
        //prepare
        let storageType = try SimpleStorageType(simpleStorage: sut, storageType: "mytype")

        //execute
        try storageType.addStorageTypeAttribute(attribute: Attribute(name: "myvalue", type: .uuid, nullable: true))

        //verify
        XCTAssertEqual(try table("mytype").last, TableColumn(name: "myvalue", type: "TEXT", notNull: false))
    }

    func test_createAttribute_shouldAddIntegerAttribute() throws {
        //prepare
        let storageType = try SimpleStorageType(simpleStorage: sut, storageType: "mytype")

        //execute
        try storageType.addStorageTypeAttribute(attribute: Attribute(name: "myvalue", type: .integer, nullable: false))

        //verify
        XCTAssertEqual(try table("mytype").last, TableColumn(name: "myvalue", type: "INTEGER", notNull: true))
    }

    func test_createAttribute_shouldAddIntegerAttribute_Nullable() throws {
        //prepare
        let storageType = try SimpleStorageType(simpleStorage: sut, storageType: "mytype")

        //execute
        try storageType.addStorageTypeAttribute(attribute: Attribute(name: "myvalue", type: .integer, nullable: true))

        //verify
        XCTAssertEqual(try table("mytype").last, TableColumn(name: "myvalue", type: "INTEGER", notNull: false))
    }

    func test_createAttribute_shouldAddBoolAttribute() throws {
        //prepare
        let storageType = try SimpleStorageType(simpleStorage: sut, storageType: "mytype")

        //execute
        try storageType.addStorageTypeAttribute(attribute: Attribute(name: "myvalue", type: .bool, nullable: false))

        //verify
        XCTAssertEqual(try table("mytype").last, TableColumn(name: "myvalue", type: "INTEGER", notNull: true))
    }

    func test_createAttribute_shouldAddBoolAttribute_Nullable() throws {
        //prepare
        let storageType = try SimpleStorageType(simpleStorage: sut, storageType: "mytype")

        //execute
        try storageType.addStorageTypeAttribute(attribute: Attribute(name: "myvalue", type: .bool, nullable: true))

        //verify
        XCTAssertEqual(try table("mytype").last, TableColumn(name: "myvalue", type: "INTEGER", notNull: false))
    }

    func test_createAttribute_shouldAddDoubleAttribute() throws {
        //prepare
        let storageType = try SimpleStorageType(simpleStorage: sut, storageType: "mytype")

        //execute
        try storageType.addStorageTypeAttribute(attribute: Attribute(name: "myvalue", type: .double, nullable: false))

        //verify
        XCTAssertEqual(try table("mytype").last, TableColumn(name: "myvalue", type: "REAL", notNull: true))
    }

    func test_createAttribute_shouldAddDoubleAttribute_Nullable() throws {
        //prepare
        let storageType = try SimpleStorageType(simpleStorage: sut, storageType: "mytype")

        //execute
        try storageType.addStorageTypeAttribute(attribute: Attribute(name: "myvalue", type: .double, nullable: true))

        //verify
        XCTAssertEqual(try table("mytype").last, TableColumn(name: "myvalue", type: "REAL", notNull: false))
    }

    func test_createAttribute_shouldAddDateAttribute() throws {
        //prepare
        let storageType = try SimpleStorageType(simpleStorage: sut, storageType: "mytype")

        //execute
        try storageType.addStorageTypeAttribute(attribute: Attribute(name: "myvalue", type: .date, nullable: false))

        //verify
        XCTAssertEqual(try table("mytype").last, TableColumn(name: "myvalue", type: "REAL", notNull: true))
    }

    func test_createAttribute_shouldAddDateAttribute_Nullable() throws {
        //prepare
        let storageType = try SimpleStorageType(simpleStorage: sut, storageType: "mytype")

        //execute
        try storageType.addStorageTypeAttribute(attribute: Attribute(name: "myvalue", type: .date, nullable: true))

        //verify
        XCTAssertEqual(try table("mytype").last, TableColumn(name: "myvalue", type: "REAL", notNull: false))
    }

    func test_createAttribute_shouldAddRelationshipAttribute() throws {
        //prepare
        let storageType = try SimpleStorageType(simpleStorage: sut, storageType: "mytype")
        _ = try SimpleStorageType(simpleStorage: sut, storageType: "myrelationshiptype")

        //execute
        try storageType.addStorageTypeAttribute(attribute: Attribute(name: "myrelationship", type: .relationship("myrelationshiptype"), nullable: false))

        //verify
        XCTAssertEqual(try table("mytype").last, TableColumn(name: "myrelationship", type: "TEXT", notNull: true))
    }

    func test_createAttribute_shouldAddRelationshipAttribute_Nullable() throws {
        //prepare
        let storageType = try SimpleStorageType(simpleStorage: sut, storageType: "mytype")
        _ = try SimpleStorageType(simpleStorage: sut, storageType: "myrelationshiptype")

        //execute
        try storageType.addStorageTypeAttribute(attribute: Attribute(name: "myrelationship", type: .relationship("myrelationshiptype"), nullable: true))

        //verify
        XCTAssertEqual(try table("mytype").last, TableColumn(name: "myrelationship", type: "TEXT", notNull: false))
    }

    func test_storageTypeVersion_shouldReturnIntially0() throws {
        //prepare
        let storageType = try SimpleStorageType(simpleStorage: sut, storageType: "mytype")

        //execute
        let version = try storageType.storageTypeVersion()

        //verify
        XCTAssertEqual(version, 0)
    }

    func test_storageTypeVersion_shouldUpdateTheStorageTypeVersion() throws {
        //prepare
        let storageType = try SimpleStorageType(simpleStorage: sut, storageType: "mytype")

        //execute
        try storageType.setStorageTypeVersion(version: 3)

        //verify
        XCTAssertEqual(try sut.storageTypeVersion(storageType: "mytype"), 3)
    }

    func test_removeStorageType() throws {
        //prepare
        let storageType = try TestUtils.createStorageType(sut: sut)

        //execute
        try storageType.removeStorageType()

        //verify
        XCTAssertEqual(try table("mytype").count, 0)
    }

    func test_removeAttribute() throws {
        //prepare
        let storageType = try TestUtils.createStorageType(sut: sut)

        //execute
        try storageType.removeAttribute(attribute: "myinteger")

        //vefify
        XCTAssertNil(try table("mytype").first { $0.name == "myinteger" })
    }

    func table(_ storageType: String) throws -> [TableColumn] {
        let statement = try sut.sqlite.prepareStatement(sql: "PRAGMA table_info(\(storageType))")

        var structure = [TableColumn]()
        while sqlite3_step(statement) == SQLITE_ROW {
            structure.append(
                TableColumn(
                    name: String(cString: sqlite3_column_text(statement, 1)),
                    type: String(cString: sqlite3_column_text(statement, 2)),
                    notNull: Int(sqlite3_column_int64(statement, 3)) != 0
                )
            )
        }

        return structure
    }

    struct TableColumn: Equatable {
        let name: String
        let type: String
        let notNull: Bool
    }
}
