//
//  SimpleStorageCreateOrUpdateTests.swift
//  SimpleStorageTests
//
//  Created by Dominik Gauggel on 31.10.20.
//

import XCTest
import SQLite3
@testable import SimpleStorage

class SimpleStorageCreateOrUpdateTests: XCTestCase {
    var sut: SimpleStorage!

    override func setUp() {
        super.setUp()
        
        sut = try! SimpleStorage(configuration: .defaultInMemory)
    }

    func test_createOrUpdate_create_shouldAddNewRow() throws {
        //prepare
        let storageType = try SimpleStorageType(simpleStorage: sut, storageType: "mytype")

        //execute
        try storageType.createOrUpdate(item: Item(id: UUID(), values: [:]))

        //verify
        XCTAssertEqual(try TestUtils.count(sut: sut, storageType: "mytype"), 1)
    }

    func test_createOrUpdate_update_shouldUpdateExistingRow() throws {
        //prepare
        let id = UUID()
        let storageType = try SimpleStorageType(simpleStorage: sut, storageType: "mytype")

        try storageType.createOrUpdate(item: Item(id: id, values: [:]))

        //execute
        try storageType.createOrUpdate(item: Item(id: id, values: [:]))

        //verify
        XCTAssertEqual(try TestUtils.count(sut: sut, storageType: "mytype"), 1)
    }

    func test_createOrUpdate_update_shouldOnlyTouchUpdatedAt() throws {
        //prepare
        let id = UUID()
        let storageType = try SimpleStorageType(simpleStorage: sut, storageType: "mytype")

        try storageType.createOrUpdate(item: Item(id: id, values: [:]))
        let before = try storageType.find(id: id)

        let expectation = self.expectation(description: "Update")
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1) {
            //execute
            try? self.sut.createOrUpdate(storageType: "mytype", item: Item(id: id, values: [:]))
            expectation.fulfill()
        }

        waitForExpectations(timeout: 2, handler: nil)

        //verify
        let after = try sut.find(storageType: "mytype", id: id)
        XCTAssertEqual(try before!.value(name: "created_at") as Date, try after!.value(name: "created_at") as Date)
        XCTAssertLessThan(try before!.value(name: "updated_at") as Date, try after!.value(name: "updated_at") as Date)
    }

    func test_createOrUpdate_shouldStoreTypes() throws {
        let storageType = try TestUtils.createStorageType(sut: sut)

        //execute
        try storageType.createOrUpdate(item: TestUtils.createItem())

        //verify
        XCTAssertEqual(try TestUtils.count(sut: sut, storageType: "mytype"), 1)
    }

    func test_createOrUpdate_shouldStoreNullableTypes() throws {
        let storageType = try TestUtils.createStorageType(sut: sut, nullable: true)

        //execute
        try storageType.createOrUpdate(item: TestUtils.createItem())

        //verify
        XCTAssertEqual(try TestUtils.count(sut: sut, storageType: "mytype"), 1)
    }

    func test_createOrUpdate_shouldStoreNullTypes() throws {
        let storageType = try TestUtils.createStorageType(sut: sut, nullable: true)

        //execute
        try storageType.createOrUpdate(item: Item(id: UUID(), values: [:]))

        //verify
        XCTAssertEqual(try TestUtils.count(sut: sut, storageType: "mytype"), 1)
    }

    func test_createOrUpdate_shouldStoreRelationship() throws {
        let storageType = try TestUtils.createStorageType(sut: sut, nullable: true)
        let relationshipType = try SimpleStorageType(simpleStorage: sut, storageType: "myrelationship")
        try relationshipType.addAttribute(attribute: Attribute(name: "mytype_id", type: .relationship(storageType), nullable: false))

        let item = TestUtils.createItem()
        try storageType.createOrUpdate(item: item)

        let relationshipItem = Item(values: ["mytype_id": item.id])

        //execute
        try relationshipType.createOrUpdate(item: relationshipItem)

        //verify
        XCTAssertEqual(try TestUtils.count(sut: sut, storageType: "mytype"), 1)
        XCTAssertEqual(try TestUtils.count(sut: sut, storageType: "myrelationship"), 1)
    }
}
