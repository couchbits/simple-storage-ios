//
//  StorageItemTests.swift
//  presence
//
//  Created by Dominik Gauggel on 06.08.19.
//  Copyright © 2019 couchbits GmbH. All rights reserved.
//

import Foundation
import XCTest

class StorageItemTests: XCTestCase {
    var sut: StorageItem!
    let uuid = UUID()
    override func setUp() {
        super.setUp()
        sut = StorageItem(values: [1, uuid, "any"])
    }
    func testValue_shouldReturnTheValue() throws {
        XCTAssertEqual(try sut.value(index: 0) as Int, 1)
        XCTAssertEqual(try sut.value(index: 1) as UUID, uuid)
        XCTAssertEqual(try sut.value(index: 2) as String, "any")
    }

    func testValue_shouldThrowErrorIfValueTypeIsNotMatching() throws {
        XCTAssertThrowsError(try sut.value(index: 0) as Double)
    }

    func testValue_shouldThrowErrorIfIndexOutOfBounds() throws {
        XCTAssertThrowsError(try sut.value(index: 3) as Any)
    }

    func testValue_shouldThrowErrorIfIndexIsNegative() throws {
        XCTAssertThrowsError(try sut.value(index: -1) as Any)
    }
}
