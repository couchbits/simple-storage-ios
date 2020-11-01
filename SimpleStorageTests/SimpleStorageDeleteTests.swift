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
        try TestUtils.createStorageType(sut: sut)
        try sut.createOrUpdate(storageType: "mytype", items: [TestUtils.createItem(), TestUtils.createItem()])

        //execute
        try sut.delete(storageType: "mytype")

        //verify
        XCTAssertEqual(try TestUtils.count(sut: sut, storageType: "mytype"), 0)
    }

    func test_delete_id_shouldRemoveOnlyId() throws {
        //prepare
        try TestUtils.createStorageType(sut: sut)
        let item = TestUtils.createItem()
        try sut.createOrUpdate(storageType: "mytype", items: [item, TestUtils.createItem()])

        //execute
        try sut.delete(storageType: "mytype", id: item.id)

        //verify
        XCTAssertEqual(try TestUtils.count(sut: sut, storageType: "mytype"), 1)
    }

    func test_delete_shouldApplyConstraints() throws {
        //prepare
        try TestUtils.createStorageType(sut: sut, nullable: true)
        var item1 = TestUtils.createItem()
        item1.values["myinteger"] = 1
        var item2 = TestUtils.createItem()
        item2.values["myinteger"] = 2
        var item3 = TestUtils.createItem()
        item3.values["myinteger"] = 3
        try sut.createOrUpdate(
            storageType: "mytype",
            items: [item1, item2, item3]
        )

        //execute
        try sut.delete(
            storageType: "mytype",
            constraints: [
                Constraint(attribute: "myinteger", value: 2, operator: .greaterThanOrEqual),
                Constraint(attribute: "mystring", value: "any-string")
            ]
        )

        //verify
        XCTAssertEqual(try TestUtils.count(sut: sut, storageType: "mytype"), 1)
    }

    func test_delete_shouldRemoveTheRelationship() throws {
        try TestUtils.createStorageType(sut: sut, nullable: true)
        try sut.createStorageType(storageType: "myrelationship")
        try sut.addStorageTypeAttribute(storageType: "myrelationship", attribute: Attribute(name: "mytype_id", type: .relationship("mytype"), nullable: false))

        let item = TestUtils.createItem()
        try sut.createOrUpdate(storageType: "mytype", item: item)

        let relationshipItem = Item(values: ["mytype_id": item.id])
        try sut.createOrUpdate(storageType: "myrelationship", item: relationshipItem)

        //execute
        try sut.delete(storageType: "mytype", id: item.id)

        //verify
        XCTAssertEqual(try TestUtils.count(sut: sut, storageType: "mytype"), 0)
        XCTAssertEqual(try TestUtils.count(sut: sut, storageType: "myrelationship"), 0)
    }
}
