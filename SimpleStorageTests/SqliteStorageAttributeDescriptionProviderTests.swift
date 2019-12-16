//
//  StorageTypeTests.swift
//  presence
//
//  Created by Dominik Gauggel on 30.07.19.
//  Copyright © 2019 couchbits GmbH. All rights reserved.
//

import Foundation
import XCTest

//swiftlint:disable:next type_name
class SqliteStorageAttributeDescriptionProviderTests: XCTestCase {
    var sut: SqliteStorageAttributeDescriptionProvider!

    override func setUp() {
        super.setUp()
        sut = SqliteStorageAttributeDescriptionProvider()
    }

    func test_StoreableTypeAttribute_Int_ShouldCreateCorrectDescription_Null() {
        XCTAssertEqual(sut.description(StorageType.Attribute(name: "test-attribute", type: .integer, nullable: true)), "test-attribute INT NULL")
    }

    func test_StoreableTypeAttribute_Int_ShouldCreateCorrectDescription_NotNull() {
        XCTAssertEqual(sut.description(StorageType.Attribute(name: "test-attribute", type: .integer, nullable: false)), "test-attribute INT NOT NULL")
    }

    func test_StoreableTypeAttribute_PrimaryKey_ShouldCreateCorrectDescription_Null() {
        XCTAssertEqual(sut.description(StorageType.Attribute(name: "test-attribute", type: .uuid, nullable: true)), "test-attribute VARCHAR(37) NULL")
    }

    func test_StoreableTypeAttribute_PrimaryKey_ShouldCreateCorrectDescription_NotNull() {
        XCTAssertEqual(sut.description(StorageType.Attribute(name: "test-attribute", type: .uuid, nullable: false)), "test-attribute VARCHAR(37) NOT NULL")
    }

    func test_StoreableTypeAttribute_Bool_ShouldCreateCorrectDescription_Null() {
        XCTAssertEqual(sut.description(StorageType.Attribute(name: "test-attribute", type: .bool, nullable: true)), "test-attribute INT(1) NULL")
    }

    func test_StoreableTypeAttribute_Bool_ShouldCreateCorrectDescription_NotNull() {
        XCTAssertEqual(sut.description(StorageType.Attribute(name: "test-attribute", type: .bool, nullable: false)), "test-attribute INT(1) NOT NULL")
    }

    func test_StoreableTypeAttribute_Double_ShouldCreateCorrectDescription_Null() {
        XCTAssertEqual(sut.description(StorageType.Attribute(name: "test-attribute", type: .double, nullable: true)), "test-attribute DOUBLE NULL")
    }

    func test_StoreableTypeAttribute_Double_ShouldCreateCorrectDescription_NotNull() {
        XCTAssertEqual(sut.description(StorageType.Attribute(name: "test-attribute", type: .double, nullable: false)), "test-attribute DOUBLE NOT NULL")
    }

    func test_StoreableTypeAttribute_Date_ShouldCreateCorrectDescription_Null() {
        XCTAssertEqual(sut.description(StorageType.Attribute(name: "test-attribute", type: .date, nullable: true)), "test-attribute DOUBLE NULL")
    }

    func test_StoreableTypeAttribute_Date_ShouldCreateCorrectDescription_NotNull() {
        XCTAssertEqual(sut.description(StorageType.Attribute(name: "test-attribute", type: .date, nullable: false)), "test-attribute DOUBLE NOT NULL")
    }

    func test_StoreableTypeAttribute_Text_ShouldCreateCorrectDescription_Null() {
        XCTAssertEqual(sut.description(StorageType.Attribute(name: "test-attribute", type: .text, nullable: true)), "test-attribute TEXT NULL")
    }

    func test_StoreableTypeAttribute_Text_ShouldCreateCorrectDescription_NotNull() {
        XCTAssertEqual(sut.description(StorageType.Attribute(name: "test-attribute", type: .text, nullable: false)), "test-attribute TEXT NOT NULL")
    }

    func test_StoreableTypeAttribute_String_ShouldCreateCorrectDescription_Null() {
        XCTAssertEqual(sut.description(StorageType.Attribute(name: "test-attribute", type: .string(255), nullable: true)), "test-attribute VARCHAR(255) NULL")
    }

    func test_StoreableTypeAttribute_String_ShouldCreateCorrectDescription_NotNull() {
        XCTAssertEqual(sut.description(StorageType.Attribute(name: "test-attribute", type: .string(255), nullable: false)), "test-attribute VARCHAR(255) NOT NULL")
    }

    func test_StoreableTypeAttribute_Relationship_ShouldCreateCorrectDescription_NotNull() {
        XCTAssertEqual(sut.description(StorageType.Attribute(name: "test-attribute", type: .relationship("any-test"), nullable: false)), "test-attribute VARCHAR(37) NOT NULL REFERENCES any-test(id) ON UPDATE CASCADE ON DELETE CASCADE")
    }

    func test_StoreableTypeAttribute_Relationship_ShouldCreateCorrectDescription_Null() {
        XCTAssertEqual(sut.description(StorageType.Attribute(name: "test-attribute", type: .relationship("any-test"), nullable: true)), "test-attribute VARCHAR(37) NULL REFERENCES any-test(id) ON UPDATE SET NULL ON DELETE SET NULL")
    }
}
