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
        try sut.createStorageType(storageType: "mytype")

        //verify
        let tableDescription = try table("mytype")
        XCTAssertEqual(tableDescription[0], TableColumn(name: "id", type: "TEXT", notNull: true))
        XCTAssertEqual(tableDescription[1], TableColumn(name: "created_at", type: "REAL", notNull: true))
        XCTAssertEqual(tableDescription[2], TableColumn(name: "updated_at", type: "REAL", notNull: true))
    }

    func test_createAttribute_shouldAddStringAttribute() throws {
        //prepare
        try sut.createStorageType(storageType: "mytype")

        //execute
        try sut.addStorageTypeAttribute(storageType: "mytype", attribute: Attribute(name: "myvalue", type: .string, nullable: false))

        //verify
        XCTAssertEqual(try table("mytype").last, TableColumn(name: "myvalue", type: "TEXT", notNull: true))
    }

    func test_createAttribute_shouldAddStringAttribute_Nullable() throws {
        //prepare
        try sut.createStorageType(storageType: "mytype")

        //execute
        try sut.addStorageTypeAttribute(storageType: "mytype", attribute: Attribute(name: "myvalue", type: .string, nullable: true))

        //verify
        XCTAssertEqual(try table("mytype").last, TableColumn(name: "myvalue", type: "TEXT", notNull: false))
    }

    func test_createAttribute_shouldAddUUIDAttribute() throws {
        //prepare
        try sut.createStorageType(storageType: "mytype")

        //execute
        try sut.addStorageTypeAttribute(storageType: "mytype", attribute: Attribute(name: "myvalue", type: .uuid, nullable: false))

        //verify
        XCTAssertEqual(try table("mytype").last, TableColumn(name: "myvalue", type: "TEXT", notNull: true))
    }

    func test_createAttribute_shouldAddUUIDAttribute_Nullable() throws {
        //prepare
        try sut.createStorageType(storageType: "mytype")

        //execute
        try sut.addStorageTypeAttribute(storageType: "mytype", attribute: Attribute(name: "myvalue", type: .uuid, nullable: true))

        //verify
        XCTAssertEqual(try table("mytype").last, TableColumn(name: "myvalue", type: "TEXT", notNull: false))
    }

    func test_createAttribute_shouldAddIntegerAttribute() throws {
        //prepare
        try sut.createStorageType(storageType: "mytype")

        //execute
        try sut.addStorageTypeAttribute(storageType: "mytype", attribute: Attribute(name: "myvalue", type: .integer, nullable: false))

        //verify
        XCTAssertEqual(try table("mytype").last, TableColumn(name: "myvalue", type: "INTEGER", notNull: true))
    }

    func test_createAttribute_shouldAddIntegerAttribute_Nullable() throws {
        //prepare
        try sut.createStorageType(storageType: "mytype")

        //execute
        try sut.addStorageTypeAttribute(storageType: "mytype", attribute: Attribute(name: "myvalue", type: .integer, nullable: true))

        //verify
        XCTAssertEqual(try table("mytype").last, TableColumn(name: "myvalue", type: "INTEGER", notNull: false))
    }

    func test_createAttribute_shouldAddBoolAttribute() throws {
        //prepare
        try sut.createStorageType(storageType: "mytype")

        //execute
        try sut.addStorageTypeAttribute(storageType: "mytype", attribute: Attribute(name: "myvalue", type: .bool, nullable: false))

        //verify
        XCTAssertEqual(try table("mytype").last, TableColumn(name: "myvalue", type: "INTEGER", notNull: true))
    }

    func test_createAttribute_shouldAddBoolAttribute_Nullable() throws {
        //prepare
        try sut.createStorageType(storageType: "mytype")

        //execute
        try sut.addStorageTypeAttribute(storageType: "mytype", attribute: Attribute(name: "myvalue", type: .bool, nullable: true))

        //verify
        XCTAssertEqual(try table("mytype").last, TableColumn(name: "myvalue", type: "INTEGER", notNull: false))
    }

    func test_createAttribute_shouldAddDoubleAttribute() throws {
        //prepare
        try sut.createStorageType(storageType: "mytype")

        //execute
        try sut.addStorageTypeAttribute(storageType: "mytype", attribute: Attribute(name: "myvalue", type: .double, nullable: false))

        //verify
        XCTAssertEqual(try table("mytype").last, TableColumn(name: "myvalue", type: "REAL", notNull: true))
    }

    func test_createAttribute_shouldAddDoubleAttribute_Nullable() throws {
        //prepare
        try sut.createStorageType(storageType: "mytype")

        //execute
        try sut.addStorageTypeAttribute(storageType: "mytype", attribute: Attribute(name: "myvalue", type: .double, nullable: true))

        //verify
        XCTAssertEqual(try table("mytype").last, TableColumn(name: "myvalue", type: "REAL", notNull: false))
    }

    func test_createAttribute_shouldAddDateAttribute() throws {
        //prepare
        try sut.createStorageType(storageType: "mytype")

        //execute
        try sut.addStorageTypeAttribute(storageType: "mytype", attribute: Attribute(name: "myvalue", type: .date, nullable: false))

        //verify
        XCTAssertEqual(try table("mytype").last, TableColumn(name: "myvalue", type: "REAL", notNull: true))
    }

    func test_createAttribute_shouldAddDateAttribute_Nullable() throws {
        //prepare
        try sut.createStorageType(storageType: "mytype")

        //execute
        try sut.addStorageTypeAttribute(storageType: "mytype", attribute: Attribute(name: "myvalue", type: .date, nullable: true))

        //verify
        XCTAssertEqual(try table("mytype").last, TableColumn(name: "myvalue", type: "REAL", notNull: false))
    }

    func test_createAttribute_shouldAddRelationshipAttribute() throws {
        //prepare
        try sut.createStorageType(storageType: "mytype")
        try sut.createStorageType(storageType: "myrelationshiptype")

        //execute
        try sut.addStorageTypeAttribute(storageType: "mytype", attribute: Attribute(name: "myrelationship", type: .relationship("myrelationshiptype"), nullable: false))

        //verify
        XCTAssertEqual(try table("mytype").last, TableColumn(name: "myrelationship", type: "TEXT", notNull: true))
    }

    func test_createAttribute_shouldAddRelationshipAttribute_Nullable() throws {
        //prepare
        try sut.createStorageType(storageType: "mytype")
        try sut.createStorageType(storageType: "myrelationshiptype")

        //execute
        try sut.addStorageTypeAttribute(storageType: "mytype", attribute: Attribute(name: "myrelationship", type: .relationship("myrelationshiptype"), nullable: true))

        //verify
        XCTAssertEqual(try table("mytype").last, TableColumn(name: "myrelationship", type: "TEXT", notNull: false))
    }

    func test_storageTypeVersion_shouldReturnIntially0() throws {
        //prepare
        try sut.createStorageType(storageType: "mytype")

        //execute
        let version = try sut.storageTypeVersion(storageType: "mytype")

        //verify
        XCTAssertEqual(version, 0)
    }

    func test_storageTypeVersion_shouldUpdateTheStorageTypeVersion() throws {
        //prepare
        try sut.createStorageType(storageType: "mytype")

        //execute
        try sut.setStorageTypeVersion(storageType: "mytype", version: 3)

        //verify
        XCTAssertEqual(try sut.storageTypeVersion(storageType: "mytype"), 3)
    }

    func test_removeStorageType() throws {
        //prepare
        try TestUtils.createStorageType(sut: sut)

        //execute
        try sut.removeStorageType(storageType: "mytype")

        //verify
        XCTAssertEqual(try table("mytype").count, 0)
    }

    func test_removeAttribute() throws {
        //prepare
        try TestUtils.createStorageType(sut: sut)

        //execute
        try sut.removeAttribute(storageType: "mytype", attribute: "myinteger")

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
