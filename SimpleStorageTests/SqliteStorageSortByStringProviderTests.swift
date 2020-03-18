//
//  SqliteStorageSortByStringProviderTests.swift
//  SimpleStorageTests
//
//  Created by Dominik Gauggel on 18.03.20.
//

import Foundation
import XCTest
@testable import SimpleStorage

class SqliteStorageSortByStringProviderTests: XCTestCase {
    var sut = SqliteStorageSortByStringProvider()

    let attribute1 = StorageType.Attribute(name: "any-1", type: .integer, nullable: false)
    let attribute2 = StorageType.Attribute(name: "any-2", type: .integer, nullable: false)

    func test_itAddsCreatedAtASCIfNothingIsProvided() {
        XCTAssertEqual(sut.sortByString([]), "ORDER BY createdAt ASC")
    }

    func test_itCreatesOrderByStringFor1AttributeASC_AddsCreatedAtAtLeast() {
        XCTAssertEqual(sut.sortByString([StorageExpression.SortBy(attribute: attribute1, sortOrder: .ascening)]), "ORDER BY any-1 ASC, createdAt ASC")
    }

    func test_itCreatesOrderByStringFor1AttributeDESC_AddsCreatedAtAtLeast() {
        XCTAssertEqual(sut.sortByString([StorageExpression.SortBy(attribute: attribute1, sortOrder: .descending)]), "ORDER BY any-1 DESC, createdAt ASC")
    }

    func test_itCreatesOrderByStringForMoreAttribute_AddsCreatedAtAtLeast() {
        XCTAssertEqual(sut.sortByString([StorageExpression.SortBy(attribute: attribute1, sortOrder: .ascening),
                                         StorageExpression.SortBy(attribute: attribute2, sortOrder: .descending)]), "ORDER BY any-1 ASC, any-2 DESC, createdAt ASC")
    }

    func test_itSkipsCreatedAtIfCreatedAtWasGiven() {
        XCTAssertEqual(sut.sortByString([StorageExpression.SortBy(attribute: attribute1, sortOrder: .ascening),
                                         StorageExpression.SortBy(attribute: StorageType.metaAttributes.createdAt, sortOrder: .descending),
                                         StorageExpression.SortBy(attribute: attribute2, sortOrder: .descending)]), "ORDER BY any-1 ASC, createdAt DESC, any-2 DESC")
    }
}
