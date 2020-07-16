//
//  SqliteStorageConstraintStringProivderTests.swift
//  SimpleStorageTests
//
//  Created by Dominik Gauggel on 23.04.20.
//  Copyright © 2020 couchbits GmbH. All rights reserved.
//

import Foundation
import XCTest

class SqliteStorageConstraintStringProviderTests: XCTestCase {
    var sut = SqliteStorageConstraintStringProvider()

    var nullableAttribute = StorageType.Attribute(name: "nullableValue", type: .text, nullable: true)
    var nonNumeric = StorageType.Attribute(name: "nonNumeric", type: .text, nullable: false)
    var numeric = StorageType.Attribute(name: "numeric", type: .integer, nullable: false)

    func test_null_equal_shouldThrowErrorIfAttributeIsNotNullable() {
        XCTAssertThrowsError(try sut.string(constraint: StorageConstraint(attribute: nonNumeric, value: nil, constraintOperator: .equal)))
    }

    func test_notNull_equal_shouldThrowErrorIfAttributeIsNotNullable() {
        XCTAssertThrowsError(try sut.string(constraint: StorageConstraint(attribute: nonNumeric, value: nil, constraintOperator: .notEqual)))
    }

    func test_null_otherThanEqualNonEqual_shouldThrowError() {
        XCTAssertThrowsError(try sut.string(constraint: StorageConstraint(attribute: nullableAttribute, value: nil, constraintOperator: .greaterThan)))
        XCTAssertThrowsError(try sut.string(constraint: StorageConstraint(attribute: nullableAttribute, value: nil, constraintOperator: .greaterThanOrEqual)))
        XCTAssertThrowsError(try sut.string(constraint: StorageConstraint(attribute: nullableAttribute, value: nil, constraintOperator: .lessThan)))
        XCTAssertThrowsError(try sut.string(constraint: StorageConstraint(attribute: nullableAttribute, value: nil, constraintOperator: .lessThanOrEqual)))
    }

    func test_nullEqual_shouldBuildCorrectString() throws {
        XCTAssertEqual(try sut.string(constraint: StorageConstraint(attribute: nullableAttribute, value: nil, constraintOperator: .equal)), "nullableValue IS NULL")
    }

    func test_nullNotEqual_shouldBuildCorrectString() throws {
        XCTAssertEqual(try sut.string(constraint: StorageConstraint(attribute: nullableAttribute, value: nil, constraintOperator: .notEqual)), "nullableValue IS NOT NULL")
    }

    func test_GreaterThan_nonNumeric_shouldThrowError() {
        XCTAssertThrowsError(try sut.string(constraint: StorageConstraint(attribute: nonNumeric, value: "test", constraintOperator: .greaterThan)))
    }

    func test_GreaterThanEqual_nonNumeric_shouldThrowError() {
        XCTAssertThrowsError(try sut.string(constraint: StorageConstraint(attribute: nonNumeric, value: "test", constraintOperator: .greaterThanOrEqual)))
    }

    func test_LessThan_nonNumeric_shouldThrowError() {
        XCTAssertThrowsError(try sut.string(constraint: StorageConstraint(attribute: nonNumeric, value: "test", constraintOperator: .lessThan)))
    }

    func test_LessThanEqual_nonNumeric_shouldThrowError() {
        XCTAssertThrowsError(try sut.string(constraint: StorageConstraint(attribute: nonNumeric, value: "test", constraintOperator: .lessThanOrEqual)))
    }

    func test_nonNumeric_equal_shouldBuildCorrectString() {
        XCTAssertEqual(try sut.string(constraint: StorageConstraint(attribute: nonNumeric, value: "test", constraintOperator: .equal)), "nonNumeric = ?")
    }

    func test_nonNumeric_notEqual_shouldBuildCorrectString() {
        XCTAssertEqual(try sut.string(constraint: StorageConstraint(attribute: nonNumeric, value: "test", constraintOperator: .notEqual)), "nonNumeric != ?")
    }

    func test_numeric_equal_shouldBuildCorrectString() {
        XCTAssertEqual(try sut.string(constraint: StorageConstraint(attribute: numeric, value: 42, constraintOperator: .equal)), "numeric = ?")
    }

    func test_numeric_notEqual_shouldBuildCorrectString() {
        XCTAssertEqual(try sut.string(constraint: StorageConstraint(attribute: numeric, value: 42, constraintOperator: .notEqual)), "numeric != ?")
    }

    func test_numeric_greaterThan_shouldBuildCorrectString() {
        XCTAssertEqual(try sut.string(constraint: StorageConstraint(attribute: numeric, value: 42, constraintOperator: .greaterThan)), "numeric > ?")
    }

    func test_numeric_greaterThanEqual_shouldBuildCorrectString() {
        XCTAssertEqual(try sut.string(constraint: StorageConstraint(attribute: numeric, value: 42, constraintOperator: .greaterThanOrEqual)), "numeric >= ?")
    }

    func test_numeric_lessThan_shouldBuildCorrectString() {
        XCTAssertEqual(try sut.string(constraint: StorageConstraint(attribute: numeric, value: 42, constraintOperator: .lessThan)), "numeric < ?")
    }

    func test_numeric_lessThanEqual_shouldBuildCorrectString() {
        XCTAssertEqual(try sut.string(constraint: StorageConstraint(attribute: numeric, value: 42, constraintOperator: .lessThanOrEqual)), "numeric <= ?")
    }
}
