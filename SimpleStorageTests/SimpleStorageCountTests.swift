//
//  SimpleStorageCountTests.swift
//  SimpleStorageTests
//
//  Created by Dominik Gauggel on 01.11.20.
//

import XCTest
import SQLite3
@testable import SimpleStorage

class SimpleStorageCountTests: XCTestCase {
    var sut: SimpleStorage!

    override func setUp() {
        super.setUp()

        sut = try! SimpleStorage(configuration: .defaultInMemory)
    }

    func test_count_shouldReturnAll() throws {
        //prepare
        let storageType = try TestUtils.createStorageType(sut: sut, nullable: true)
        try storageType.createOrUpdate(
            items: [TestUtils.createItem(), TestUtils.createItem(), TestUtils.createItem()]
        )

        //execute
        let count = try storageType.count()

        //verify
        XCTAssertEqual(count, 3)
    }

    func test_count_shouldApplyConstraint() throws {
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
        let count = try storageType.count(
            constraints: [
                Constraint(attribute: "myinteger", value: 2, operator: .greaterThanOrEqual),
                Constraint(attribute: "mystring", value: "any-string")
            ]
        )

        //verify
        XCTAssertEqual(count, 2)
    }
}
