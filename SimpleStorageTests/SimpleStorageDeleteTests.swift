//
//  SimpleStorageDeleteTests.swift
//  SimpleStorageTests
//
//  Created by Dominik Gauggel on 01.11.20.
//

import XCTest
import SQLite3
@testable import SimpleStorage

class SimpleStorageDeleteTests: XCTestCase {
    var sut: SimpleStorage!

    override func setUp() {
        super.setUp()

        sut = try! SimpleStorage(configuration: .defaultInMemory)
    }

    func test_delete_shouldRemoveAll() throws {
        //prepare
        let storageType = try TestUtils.createStorageType(sut: sut)
        try storageType.createOrUpdate(items: [TestUtils.createItem(), TestUtils.createItem()])

        //execute
        try storageType.delete()

        //verify
        XCTAssertEqual(try TestUtils.count(sut: sut, storageType: "mytype"), 0)
    }

    func test_delete_id_shouldRemoveOnlyId() throws {
        //prepare
        let storageType = try TestUtils.createStorageType(sut: sut)
        let item = TestUtils.createItem()
        try storageType.createOrUpdate(items: [item, TestUtils.createItem()])

        //execute
        try storageType.delete(id: item.id)

        //verify
        XCTAssertEqual(try TestUtils.count(sut: sut, storageType: "mytype"), 1)
    }

    func test_delete_shouldApplyConstraints() throws {
        //prepare
        let storageType = try TestUtils.createStorageType(sut: sut, nullable: true)
        var item1 = TestUtils.createItem()
        item1.values["myinteger"] = 1
        var item2 = TestUtils.createItem()
        item2.values["myinteger"] = 2
        var item3 = TestUtils.createItem()
        item3.values["myinteger"] = 3
        try storageType.createOrUpdate(
            items: [item1, item2, item3]
        )

        //execute
        try storageType.delete(
            constraints: [
                Constraint(attribute: "myinteger", value: 2, operator: .greaterThanOrEqual),
                Constraint(attribute: "mystring", value: "any-string")
            ]
        )

        //verify
        XCTAssertEqual(try TestUtils.count(sut: sut, storageType: "mytype"), 1)
    }

    func test_delete_shouldRemoveTheRelationship() throws {
        let storageType = try TestUtils.createStorageType(sut: sut, nullable: true)
        let relationshipType = try SimpleStorageType(simpleStorage: sut, storageType: "myrelationship")
        try relationshipType.addStorageTypeAttribute(attribute: Attribute(name: "mytype_id", type: .relationship("mytype"), nullable: false))

        let item = TestUtils.createItem()
        try storageType.createOrUpdate(item: item)

        let relationshipItem = Item(values: ["mytype_id": item.id])
        try relationshipType.createOrUpdate(item: relationshipItem)

        //execute
        try storageType.delete(id: item.id)

        //verify
        XCTAssertEqual(try TestUtils.count(sut: sut, storageType: "mytype"), 0)
        XCTAssertEqual(try TestUtils.count(sut: sut, storageType: "myrelationship"), 0)
    }
}
