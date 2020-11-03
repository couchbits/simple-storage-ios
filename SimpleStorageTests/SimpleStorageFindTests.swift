//
//  SimpleStorageFind.swift
//  SimpleStorageTests
//
//  Created by Dominik Gauggel on 01.11.20.
//

import XCTest
import SQLite3
@testable import SimpleStorage

class SimpleStorageFindTests: XCTestCase {
    var sut: SimpleStorage!

    override func setUp() {
        super.setUp()

        sut = try! SimpleStorage(configuration: .defaultInMemory)
    }


    func test_find_byId_shouldReturnTheRecord() throws {
        //prepare
        let storageType = try TestUtils.createStorageType(sut: sut)
        let item = TestUtils.createItem()
        try storageType.createOrUpdate(item: item)

        //execute
        let persistedItem = try sut.find(storageType: "mytype", id: item.id)

        //verify
        XCTAssertNotNil(persistedItem)
        XCTAssertEqual(persistedItem?.id, item.id)
        XCTAssertEqual(try persistedItem!.value(name: "myinteger") as Int, 42)
        XCTAssertEqual(try persistedItem!.value(name: "mystring") as String, "any-string")
        XCTAssertEqual(try persistedItem!.value(name: "mydouble"), 123.45)
        XCTAssertEqual(try persistedItem!.value(name: "mybool") as Bool, true)
        XCTAssertEqual(try persistedItem!.value(name: "myuuid") as UUID, try item.value(name: "myuuid") as UUID)
        XCTAssertEqual(try persistedItem!.value(name: "mydate") as Date, Date(timeIntervalSince1970: 420))
    }

    func test_find_byId_shouldReturnTheRecordWithNullableTypes() throws {
        //prepare
        let storageType = try TestUtils.createStorageType(sut: sut, nullable: true)
        let item = TestUtils.createItem()
        try storageType.createOrUpdate(item: item)

        //execute
        let persistedItem = try storageType.find(id: item.id)

        //verify
        XCTAssertNotNil(persistedItem)
        XCTAssertEqual(persistedItem?.id, item.id)
        XCTAssertEqual(try persistedItem!.value(name: "myinteger") as Int, 42)
        XCTAssertEqual(try persistedItem!.value(name: "mystring") as String, "any-string")
        XCTAssertEqual(try persistedItem!.value(name: "mydouble"), 123.45)
        XCTAssertEqual(try persistedItem!.value(name: "mybool") as Bool, true)
        XCTAssertEqual(try persistedItem!.value(name: "myuuid") as UUID, try item.value(name: "myuuid") as UUID)
        XCTAssertEqual(try persistedItem!.value(name: "mydate") as Date, Date(timeIntervalSince1970: 420))
    }

    func test_find_byId_shouldReturnTheRecordWithNullTypes() throws {
        //prepare
        let storageType = try TestUtils.createStorageType(sut: sut, nullable: true)
        let item = Item(id: UUID(), values: [:])
        try storageType.createOrUpdate(item: item)

        //execute
        let persistedItem = try sut.find(storageType: "mytype", id: item.id)

        //verify
        XCTAssertNotNil(persistedItem)
        XCTAssertEqual(persistedItem?.id, item.id)
        XCTAssertNil(try persistedItem?.value(name: "myinteger") as Int?)
        XCTAssertNil(try persistedItem?.value(name: "mystring") as String?)
        XCTAssertNil(try persistedItem?.value(name: "mydouble") as Double?)
        XCTAssertNil(try persistedItem?.value(name: "mybool") as Bool?)
        XCTAssertNil(try persistedItem?.value(name: "myuuid") as UUID?)
        XCTAssertNil(try persistedItem?.value(name: "mydate") as Date?)
    }

    func test_find_shouldReturnAllRows() throws {
        //prepare
        let storageType = try TestUtils.createStorageType(sut: sut, nullable: true)
        try storageType.createOrUpdate(
            items: [TestUtils.createItem(), TestUtils.createItem(), TestUtils.createItem()]
        )

        //execute
        let items = try storageType.find()

        //verify
        XCTAssertEqual(items.count, 3)
    }

    func test_find_limit_shouldLimitTheResults() throws {
        //prepare
        let storageType = try TestUtils.createStorageType(sut: sut, nullable: true)
        try storageType.createOrUpdate(
            items: [TestUtils.createItem(), TestUtils.createItem(), TestUtils.createItem()]
        )

        //execute
        let items = try sut.find(storageType: "mytype", expression: Expression(limit: Expression.Limit(limit: 2)))

        //verify
        XCTAssertEqual(items.count, 2)
    }

    func test_find_shouldSortByDefault() throws {
        //prepare
        let storageType = try TestUtils.createStorageType(sut: sut, nullable: true)
        let item1 = TestUtils.createItem()
        let item2 = TestUtils.createItem()
        let item3 = TestUtils.createItem()
        try storageType.createOrUpdate(
            items: [item1, item2, item3]
        )

        //execute
        let items = try sut.find(storageType: "mytype")

        //verify
        XCTAssertEqual(items.map { $0.id }, [item1.id, item2.id, item3.id])
    }

    func test_find_shouldSortBy() throws {
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
        let items = try sut.find(
            storageType: "mytype",
            expression: Expression(sortedBy: [Expression.SortBy(attribute: "myinteger", sortOrder: .descending)])
        )

        //verify
        XCTAssertEqual(items.map { $0.id }, [item3.id, item2.id, item1.id])
    }

    func test_find_shouldApplyConstraints() throws {
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
        let items = try storageType.find(
            expression: Expression(
                constraints: [
                    Constraint(attribute: "myinteger", value: 2, operator: .greaterThanOrEqual),
                    Constraint(attribute: "mystring", value: "any-string")
                ]
            )
        )

        //verify
        XCTAssertEqual(items.map { $0.id }, [item2.id, item3.id])
    }

    func test_find_shouldReadTheRelationship() throws {
        let storageType = try TestUtils.createStorageType(sut: sut, nullable: true)
        let relationshipType = try SimpleStorageType(simpleStorage: sut, storageType: "myrelationship")
        try relationshipType.addAttribute(attribute: Attribute(name: "mytype_id", type: .relationship(storageType), nullable: false))

        let item = TestUtils.createItem()
        try storageType.createOrUpdate(item: item)

        let relationshipItem = Item(values: ["mytype_id": item.id])
        try relationshipType.createOrUpdate(item: relationshipItem)

        //execute
        let persistedRelationshipItem = try relationshipType.find(id: relationshipItem.id)

        //verify
        XCTAssertEqual(try persistedRelationshipItem!.value(name: "mytype_id") as UUID, item.id)
    }
}
