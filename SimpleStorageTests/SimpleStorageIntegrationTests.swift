//
//  SqliteStorageTests.swift
//  presence
//
//  Created by Dominik Gauggel on 29.07.19.
//  Copyright © 2019 couchbits GmbH. All rights reserved.
//

import Foundation
import XCTest
import SQLite3

class SimpleStorageTests: XCTestCase {
    var sut: SimpleStorage!
    var idProvider: IdProviderStub!
    var dateProvider: DateProviderStub!
    var storageType = StorageType(name: "my_type", attributes: [StorageType.Attribute(name: "anyid", type: .uuid, nullable: false),
                                                                StorageType.Attribute(name: "name", type: .string(255), nullable: false),
                                                                StorageType.Attribute(name: "active", type: .bool, nullable: false),
                                                                StorageType.Attribute(name: "value_int", type: .integer, nullable: false),
                                                                StorageType.Attribute(name: "value_double", type: .double, nullable: false),
                                                                StorageType.Attribute(name: "timestamp", type: .date, nullable: false),
                                                                StorageType.Attribute(name: "any", type: .text, nullable: false)])

    let url = URL(fileURLWithPath: "/tmp/StorageTests.sqlite")

    override func setUp() {
        super.setUp()
        idProvider = IdProviderStub()
        dateProvider = DateProviderStub()
        sut = try? SimpleStorage(configuration: .default,
                                 idProvider: idProvider,
                                 dateProvider: dateProvider,
                                 attributeDescriptionProvider: SqliteStorageAttributeDescriptionProvider(),
                                 defaultValueDescriptionProvider: SqliteStorageAttributeDefaultValueDescriptionProvider(),
                                 sortByStringProvider: SqliteStorageSortByStringProvider(),
                                 constraintStringProvider: SqliteStorageConstraintStringProvider(),
                                 syncRunner: DefaultSyncRunner())
    }

    override func tearDown() {
        super.tearDown()
        sut = nil
        do {
            try FileManager.default.removeItem(at: url)
        } catch {
            print("Cleanup failed: \(error)")
        }
    }

    @discardableResult
    fileprivate func createRow() throws -> StorageItem {
        return try sut.save(storageType: storageType, item: StorageItem(values: [UUID(), "any-name-1", true, 42, 500.5, Date(timeIntervalSince1970: 5000), "any-text-1"]))
    }

    func test_create_shouldCreateTheTable() throws {
        //prepare
        let helper = try SqliteTestHelper(handle: sut.handle)

        //execute
        try sut.createStorageType(storageType: storageType)

        //verify
        XCTAssertEqual(try helper.existsTable(storageType.name), 1)
    }

    func test_create_shouldStoreSchemaVersion0() throws {
        //execute
        try sut.createStorageType(storageType: storageType)

        //verify
        XCTAssertEqual(try sut.storageTypeVersion(storageType: storageType), 0)
    }

    func test_incrementStorageTypeVersion_shouldStoreNextVersionNumber() throws {
        //prepare
        try sut.createStorageType(storageType: storageType)
        try sut.incrementStorageTypeVersion(storageType: storageType)

        //execute
        try sut.incrementStorageTypeVersion(storageType: storageType)

        //verify
        XCTAssertEqual(try sut.storageTypeVersion(storageType: storageType), 2)
    }

    func test_updateStorageType_shouldAddTheNewAttributes() throws {
        //prepare
        try sut.createStorageType(storageType: storageType)
        let item = try sut.save(storageType: storageType, item: StorageItem(values: [UUID(), "any-name", true, 42, 500.5, Date(timeIntervalSince1970: 5000), "any-text"]))

        //execute
        let newAttribute = StorageType.Attribute(name: "new_value_int", type: .integer, nullable: false)
        let actualStorageType = try sut.addAttribute(storageType: storageType, attribute: newAttribute, defaultValue: 100, onSchemaVersion: 0)

        //verify
        XCTAssertEqual(try sut.object(storageType: actualStorageType, id: item.meta?.id ?? UUID()).value(index: 7), 100)
    }

    func test_create_shouldThrowErrorIfStorageTypeUseNotAllowedName_id() throws {
        //execute & verify
        XCTAssertThrowsError(try sut.createStorageType(storageType: StorageType(name: "any", attributes: [StorageType.Attribute(name: "id", type: .uuid, nullable: false)])))
    }

    func test_create_shouldThrowErrorIfStorageTypeUseNotAllowedName_createdAt() throws {
        //execute & verify
        XCTAssertThrowsError(try sut.createStorageType(storageType: StorageType(name: "any", attributes: [StorageType.Attribute(name: "createdAt", type: .date, nullable: false)])))
    }

    func test_create_shouldThrowErrorIfStorageTypeUseNotAllowedName_updatedAt() throws {
        //execute & verify
        XCTAssertThrowsError(try sut.createStorageType(storageType: StorageType(name: "any", attributes: [StorageType.Attribute(name: "updatedAt", type: .date, nullable: false)])))
    }

    func test_create_shouldNotCreateTheTableIfAlreadyExists() throws {
        //prepare
        let helper = try SqliteTestHelper(handle: sut.handle)
        try sut.createStorageType(storageType: storageType)

        //execute
        try sut.createStorageType(storageType: storageType)

        //verify
        XCTAssertEqual(try helper.existsTable(storageType.name), 1)
    }

    func test_save_shouldStoreTheNewItem() throws {
        //prepare
        let helper = try SqliteTestHelper(handle: sut.handle)
        try sut.createStorageType(storageType: storageType)

        //execute
        try sut.save(storageType: storageType, item: StorageItem(values: [UUID(), "any-name", true, 42, 500.5, Date(timeIntervalSince1970: 5000), "any-text"]))

        //verify
        XCTAssertEqual(try helper.count(tableName: storageType.name), 1)
    }

    func test_save_batch_shouldStoreTheNewItems() throws {
        //prepare
        let helper = try SqliteTestHelper(handle: sut.handle)
        try sut.createStorageType(storageType: storageType)

        //execute
        try sut.save(storageType: storageType, items: [
            StorageItem(values: [UUID(), "any-name", true, 42, 500.5, Date(timeIntervalSince1970: 5000), "any-text"]),
            StorageItem(values: [UUID(), "any-name", true, 42, 500.5, Date(timeIntervalSince1970: 5000), "any-text"]),
            StorageItem(values: [UUID(), "any-name", true, 42, 500.5, Date(timeIntervalSince1970: 5000), "any-text"])])

        //verify
        XCTAssertEqual(try helper.count(tableName: storageType.name), 3)
    }

    func test_save_batch_shouldStoreTheNewItems2() throws {
        //prepare
        let helper = try SqliteTestHelper(handle: sut.handle)
        try sut.createStorageType(storageType: storageType)

        //execute
        var items = [StorageItem]()
        for i in 0...11000 {
            items.append(StorageItem(values: [UUID(), "any-name", true, i, 500.5, Date(timeIntervalSince1970: 5000), "any-text"]))
        }
        print("PERSIST START: \(Date())")
        try sut.save(storageType: storageType, items: items)
        print("PERSIST END: \(Date())")

        //verify
        XCTAssertEqual(try helper.count(tableName: storageType.name), 11001)
    }

    func test_save_shouldUpdateAnExistingItem() throws {
        //prepare
        let helper = try SqliteTestHelper(handle: sut.handle)
        try sut.createStorageType(storageType: storageType)
        let createdAt = Date()
        dateProvider.stubbedDate = createdAt
        let item = try sut.save(storageType: storageType, item: StorageItem(values: [UUID(), "any-name", true, 42, 500.5, Date(timeIntervalSince1970: 5000), "any-text"]))

        //execute
        let uuid = UUID()
        let updatedAt = Date()
        dateProvider.stubbedDate = updatedAt
        try sut.save(storageType: storageType, item: StorageItem(meta: item.meta, values: [uuid, "any-name-updated", false, 43, 600.6, Date(timeIntervalSince1970: 6000), "any-text-updated"]))

        //verify
        let id = item.meta?.id ?? UUID()
        XCTAssertEqual(try helper.count(tableName: storageType.name), 1)
        let updatedItem = try sut.object(storageType: storageType, id: id)

        XCTAssertEqual(updatedItem.meta, StorageItem.Meta(id: id, createdAt: createdAt, updatedAt: updatedAt))
        XCTAssertEqual(try updatedItem.value(index: 0) as UUID, uuid)
        XCTAssertEqual(try updatedItem.value(index: 1) as String, "any-name-updated")
        XCTAssertEqual(try updatedItem.value(index: 2) as Bool, false)
        XCTAssertEqual(try updatedItem.value(index: 3) as Int, 43)
        XCTAssertEqual(try updatedItem.value(index: 4) as Double, 600.6)
        XCTAssertEqual(try updatedItem.value(index: 5) as Date, Date(timeIntervalSince1970: 6000))
        XCTAssertEqual(try updatedItem.value(index: 6) as String, "any-text-updated")
    }

    func test_all_shouldReadAllRows_andSortDefaultByCreatedAtASC() throws {
        //prepare
        try sut.createStorageType(storageType: storageType)
        let anyId1 = UUID()
        let anyId2 = UUID()
        dateProvider.stubbedDate = Date(timeIntervalSince1970: 4500)
        try sut.save(storageType: storageType, item: StorageItem(values: [anyId1, "any-name-1", true, 42, 500.5, Date(timeIntervalSince1970: 5000), "any-text-1"]))
        idProvider.stubbedId = UUID()
        dateProvider.stubbedDate = Date(timeIntervalSince1970: 5000)
        try sut.save(storageType: storageType, item: StorageItem(values: [anyId2, "any-name-2", false, 43, 600.6, Date(timeIntervalSince1970: 6000), "any-text-2"]))

        //execute
        let values = try sut.all(storageType: storageType)

        //verify
        XCTAssertEqual(values.count, 2)
        XCTAssertEqual(values[1].meta, StorageItem.Meta(id: idProvider.id, createdAt: dateProvider.currentDate, updatedAt: dateProvider.currentDate))
        XCTAssertEqual(try values[1].value(index: 0) as UUID, anyId2)
        XCTAssertEqual(try values[1].value(index: 1) as String, "any-name-2")
        XCTAssertEqual(try values[1].value(index: 2) as Bool, false)
        XCTAssertEqual(try values[1].value(index: 3) as Int, 43)
        XCTAssertEqual(try values[1].value(index: 4) as Double, 600.6)
        XCTAssertEqual(try values[1].value(index: 5) as Date, Date(timeIntervalSince1970: 6000))
        XCTAssertEqual(try values[1].value(index: 6) as String, "any-text-2")
    }

    func test_object_shouldReadTheObjectWithTheGivenId() throws {
        //prepare
        try sut.createStorageType(storageType: storageType)
        let anyId = UUID()
        try sut.save(storageType: storageType, item: StorageItem(values: [UUID(), "any-name-1", true, 42, 500.5, Date(timeIntervalSince1970: 5000), "any-text-1"]))
        idProvider.stubbedId = UUID()
        dateProvider.stubbedDate = Date(timeIntervalSince1970: 5000)
        try sut.save(storageType: storageType, item: StorageItem(values: [anyId, "any-name-2", false, 43, 600.6, Date(timeIntervalSince1970: 6000), "any-text-2"]))

        //execute
        let values = try sut.object(storageType: storageType, id: idProvider.id)

        //verify
        XCTAssertEqual(values.meta, StorageItem.Meta(id: idProvider.id, createdAt: dateProvider.currentDate, updatedAt: dateProvider.currentDate))
        XCTAssertEqual(try values.value(index: 0) as UUID, anyId)
        XCTAssertEqual(try values.value(index: 1) as String, "any-name-2")
        XCTAssertEqual(try values.value(index: 2) as Bool, false)
        XCTAssertEqual(try values.value(index: 3) as Int, 43)
        XCTAssertEqual(try values.value(index: 4) as Double, 600.6)
        XCTAssertEqual(try values.value(index: 5) as Date, Date(timeIntervalSince1970: 6000))
        XCTAssertEqual(try values.value(index: 6) as String, "any-text-2")
    }

    func test_object_shouldReadTheObjectWithNullableValues() throws {
        //prepare
        dateProvider.stubbedDate = Date()
        let storageType = StorageType(name: self.storageType.name, attributes: self.storageType.attributes.map { StorageType.Attribute(name: $0.name, type: $0.type, nullable: true) })
        try sut.createStorageType(storageType: storageType)

        let values: [StorageStorableType?] = [nil, nil, nil, nil, nil, nil, nil]
        idProvider.stubbedId = UUID()
        try sut.save(storageType: storageType, item: StorageItem(values: values))

        //execute
        let object = try sut.object(storageType: storageType, id: idProvider.id)

        //verify
        XCTAssertEqual(object.meta, StorageItem.Meta(id: idProvider.id, createdAt: dateProvider.currentDate, updatedAt: dateProvider.currentDate))
        XCTAssertNil(try object.value(index: 0) as UUID?)
        XCTAssertNil(try object.value(index: 1) as String?)
        XCTAssertNil(try object.value(index: 2) as Bool?)
        XCTAssertNil(try object.value(index: 3) as Int?)
        XCTAssertNil(try object.value(index: 4) as Double?)
        XCTAssertNil(try object.value(index: 5) as Date?)
        XCTAssertNil(try object.value(index: 6) as String?)
    }

    func test_object_shouldThrowNotFoundErrorIfObjectWithIdIsNotAvailable() throws {
        //prepare
        try sut.createStorageType(storageType: storageType)

        //execute & verify
        XCTAssertThrowsError(try sut.object(storageType: storageType, id: UUID()), "") { (error) in
            guard case StorageError.notFound(_) = error else {
                XCTFail("wrong error: \(error)")
                return
            }
        }
    }

    func test_delete_shouldDeleteTheObject() throws {
        //prepare
        try sut.createStorageType(storageType: storageType)
        let object = try sut.save(storageType: storageType, item: StorageItem(values: [UUID(), "any-name-1", true, 42, 500.5, Date(timeIntervalSince1970: 5000), "any-text-1"]))

        //execute
        try sut.delete(storageType: storageType, id: object.meta?.id ?? UUID())

        //verify
        XCTAssertEqual(try sut.all(storageType: storageType).count, 0)
    }

    func test_delete_shouldOnlyDeleteTheObjectAndNotTouchOtherObjects() throws {
        //prepare
        try sut.createStorageType(storageType: storageType)
        let object = try sut.save(storageType: storageType, item: StorageItem(values: [UUID(), "any-name-1", true, 42, 500.5, Date(timeIntervalSince1970: 5000), "any-text-1"]))
        let object2 = try sut.save(storageType: storageType, item: StorageItem(values: [UUID(), "any-name-1", true, 42, 500.5, Date(timeIntervalSince1970: 5000), "any-text-1"]))

        //execute
        try sut.delete(storageType: storageType, id: object.meta?.id ?? UUID())

        //verify
        let all = try sut.all(storageType: storageType) 
        XCTAssertEqual(all.count, 1)
        XCTAssertEqual(all.first?.meta?.id, object2.meta?.id)
    }

    //relationship
    var relatedStorageType = StorageType(name: "my_releated_type", attributes: [StorageType.Attribute(name: "name", type: .string(255), nullable: false),
                                                                                StorageType.Attribute(name: "my_type_id", type: .relationship("my_type"), nullable: false)])

    func test_initialize_shouldTheRelatedTable() throws {
        //prepare
        let helper = try SqliteTestHelper(handle: sut.handle)
        try sut.createStorageType(storageType: storageType)

        //execute
        try sut.createStorageType(storageType: relatedStorageType)

        //verify
        XCTAssertEqual(try helper.existsTable(relatedStorageType.name), 1)
    }

    func test_releated_shouldDeleteReferencedTypeIfRelatedObjectsGetsDeleted() throws {
        //prepare
        try sut.createStorageType(storageType: storageType)
        try sut.createStorageType(storageType: relatedStorageType)

        let object = try sut.save(storageType: storageType, item: StorageItem(values: [UUID(), "any-name", true, 42, 500.5, Date(timeIntervalSince1970: 5000), "any-text-1"]))
        try sut.save(storageType: relatedStorageType, item: StorageItem(values: ["any-related-name", object.meta?.id ?? UUID()]))

        //execute
        try sut.delete(storageType: storageType, id: object.meta?.id ?? UUID())

        //verify
        XCTAssertEqual(try sut.all(storageType: relatedStorageType).count, 0)
    }

    func test_releated_shouldSetNullIfRelatedObjectsGetsDeleted() throws {
        //prepare
        var attributes = self.relatedStorageType.attributes
        attributes[1] = StorageType.Attribute(name: attributes[1].name, type: attributes[1].type, nullable: true)
        let relatedStorageType = StorageType(name: self.relatedStorageType.name, attributes: attributes)

        try sut.createStorageType(storageType: storageType)
        try sut.createStorageType(storageType: relatedStorageType)

        let object = try sut.save(storageType: storageType, item: StorageItem(values: [UUID(), "any-name", true, 42, 500.5, Date(timeIntervalSince1970: 5000), "any-text-1"]))
        try sut.save(storageType: relatedStorageType, item: StorageItem(values: ["any-related-name", object.meta?.id ?? UUID()]))

        //execute
        try sut.delete(storageType: storageType, id: object.meta?.id ?? UUID())

        //verify
        let all = try sut.all(storageType: relatedStorageType)
        XCTAssertEqual(all.count, 1)
        let nullableId: UUID? = try all.first?.value(index: 1)
        XCTAssertNil(nullableId)
    }

    func test_releated_shouldNotDeleteRelatedTypeIfRelatedIfReferencedTypeGetsDelete() throws {
        //prepare
        try sut.createStorageType(storageType: storageType)
        try sut.createStorageType(storageType: relatedStorageType)

        let object = try sut.save(storageType: storageType, item: StorageItem(values: [UUID(), "any-name", true, 42, 500.5, Date(timeIntervalSince1970: 5000), "any-text-1"]))
        let object2 = try sut.save(storageType: relatedStorageType, item: StorageItem(values: ["any-related-name", object.meta?.id ?? UUID()]))

        //execute
        try sut.delete(storageType: relatedStorageType, id: object2.meta?.id ?? UUID())

        //verify
        XCTAssertEqual(try sut.all(storageType: relatedStorageType).count, 0)
        XCTAssertEqual(try sut.all(storageType: storageType).count, 1)
    }

    func test_find_shouldReturnOnlyTheItemsWhichIncludesTheConstraints() throws {
        //prepare
        try sut.createStorageType(storageType: storageType)
        let uuidToFind = UUID()
        try sut.save(storageType: storageType, item: StorageItem(values: [UUID(), "any-name-1", true, 42, 500.5, Date(timeIntervalSince1970: 5000), "any-text-1"]))
        try sut.save(storageType: storageType, item: StorageItem(values: [uuidToFind, "any-name-to-find", true, 42, 500.5, Date(timeIntervalSince1970: 5000), "any-text-2"]))
        try sut.save(storageType: storageType, item: StorageItem(values: [UUID(), "any-name-to-find", true, 42, 500.5, Date(timeIntervalSince1970: 5000), "any-text-3"]))
        try sut.save(storageType: storageType, item: StorageItem(values: [uuidToFind, "any-name-2", true, 42, 500.5, Date(timeIntervalSince1970: 5000), "any-text-4"]))

        //execute
        let items = try sut.find(storageType: storageType, expression: StorageExpression(constraints: [StorageConstraint(attribute: StorageType.Attribute(name: "anyid", type: .uuid, nullable: false), value: uuidToFind),
                                                                                                       StorageConstraint(attribute: StorageType.Attribute(name: "name", type: .text, nullable: false), value: "any-name-to-find")]))

        //verify
        XCTAssertEqual(items.count, 1)
        XCTAssertEqual(items.first?.values[0] as? UUID, uuidToFind)
        XCTAssertEqual(items.first?.values[1] as? String, "any-name-to-find")
    }

    func test_delete_shouldDeleteOnlyTheItemsWhichIncludesTheConstraints() throws {
        //prepare
        try sut.createStorageType(storageType: storageType)
        let uuidToFind = UUID()
        try sut.save(storageType: storageType, item: StorageItem(values: [UUID(), "any-name-1", true, 42, 500.5, Date(timeIntervalSince1970: 5000), "any-text-1"]))
        let toDelete = try sut.save(storageType: storageType, item: StorageItem(values: [uuidToFind, "any-name-to-find", true, 42, 500.5, Date(timeIntervalSince1970: 5000), "any-text-2"]))
        try sut.save(storageType: storageType, item: StorageItem(values: [UUID(), "any-name-to-find", true, 42, 500.5, Date(timeIntervalSince1970: 5000), "any-text-3"]))
        try sut.save(storageType: storageType, item: StorageItem(values: [uuidToFind, "any-name-2", true, 42, 500.5, Date(timeIntervalSince1970: 5000), "any-text-4"]))

        //execute
        try sut.delete(storageType: storageType, by: [StorageConstraint(attribute: StorageType.Attribute(name: "anyid", type: .uuid, nullable: false), value: uuidToFind),
                                                      StorageConstraint(attribute: StorageType.Attribute(name: "name", type: .text, nullable: false), value: "any-name-to-find")])

        //verify
        let items = try sut.all(storageType: storageType)
        XCTAssertEqual(items.count, 3)
        XCTAssertEqual(items.filter { $0.meta?.id == toDelete.meta?.id }.count, 0)
    }

    func test_delete_mulitpleIds_shouldDeleteTheRowsWithGivenIds() throws {
        //prepare
        try sut.createStorageType(storageType: storageType)
        let object1 = try sut.save(storageType: storageType, item: StorageItem(values: [UUID(), "any-name-1", true, 42, 500.5, Date(timeIntervalSince1970: 5000), "any-text-1"]))
        let object2 = try sut.save(storageType: storageType, item: StorageItem(values: [UUID(), "any-name-1", true, 42, 500.5, Date(timeIntervalSince1970: 5000), "any-text-1"]))
        let object3 = try sut.save(storageType: storageType, item: StorageItem(values: [UUID(), "any-name-1", true, 42, 500.5, Date(timeIntervalSince1970: 5000), "any-text-1"]))

        //execute
        try sut.delete(storageType: storageType, ids: [object1.meta?.id, object2.meta?.id].compactMap { $0 })

        //verify
        XCTAssertThrowsError(try sut.object(storageType: storageType, id: object1.meta?.id ?? UUID()))
        XCTAssertThrowsError(try sut.object(storageType: storageType, id: object2.meta?.id ?? UUID()))
        let all = try sut.all(storageType: storageType)
        XCTAssertEqual(all.count, 1)
        XCTAssertEqual(all.first?.meta?.id, object3.meta?.id)
    }

    func test_find_shouldReturnOnlyTheItemsWhichIncludesTheConstraints_nullable() throws {
        //prepare
        var attributes = self.storageType.attributes
        attributes[1] = StorageType.Attribute(name: attributes[1].name, type: attributes[1].type, nullable: true)
        let storageType = StorageType(name: self.storageType.name, attributes: attributes)

        try sut.createStorageType(storageType: storageType)
        let uuidToFind = UUID()
        try sut.save(storageType: storageType, item: StorageItem(values: [UUID(), "any-name-1", true, 42, 500.5, Date(timeIntervalSince1970: 5000), "any-text-1"]))
        try sut.save(storageType: storageType, item: StorageItem(values: [uuidToFind, nil, true, 42, 500.5, Date(timeIntervalSince1970: 5000), "any-text-2"]))
        try sut.save(storageType: storageType, item: StorageItem(values: [UUID(), nil, true, 42, 500.5, Date(timeIntervalSince1970: 5000), "any-text-3"]))
        try sut.save(storageType: storageType, item: StorageItem(values: [uuidToFind, "any-name-2", true, 42, 500.5, Date(timeIntervalSince1970: 5000), "any-text-4"]))

        //execute
        let items = try sut.find(storageType: storageType, expression: StorageExpression(constraints: [StorageConstraint(attribute: StorageType.Attribute(name: "name", type: .text, nullable: true), value: nil),
                                                                                                       StorageConstraint(attribute: StorageType.Attribute(name: "anyid", type: .uuid, nullable: false), value: uuidToFind)]))

        //verify
        XCTAssertEqual(items.count, 1)
        let first = items.first!
        XCTAssertEqual(try first.value(index: 0) as UUID, uuidToFind)
        XCTAssertNil(try first.value(index: 1) as Optional<String>)
    }

    func test_find_constraint() throws {
        //prepare
        var attributes = self.storageType.attributes
        attributes[1] = StorageType.Attribute(name: attributes[1].name, type: attributes[1].type, nullable: true)
        let storageType = StorageType(name: self.storageType.name, attributes: attributes)

        try sut.createStorageType(storageType: storageType)
        let uuidToFind = UUID()
        try sut.save(storageType: storageType, item: StorageItem(values: [UUID(), "any-name-1", true, 42, 500.5, Date(timeIntervalSince1970: 5000), "any-text-1"]))
        try sut.save(storageType: storageType, item: StorageItem(values: [uuidToFind, nil, true, 42, 500.5, Date(timeIntervalSince1970: 5000), "any-text-2"]))
        try sut.save(storageType: storageType, item: StorageItem(values: [UUID(), nil, true, 42, 500.5, Date(timeIntervalSince1970: 5000), "any-text-3"]))
        try sut.save(storageType: storageType, item: StorageItem(values: [uuidToFind, "any-name-2", true, 42, 500.5, Date(timeIntervalSince1970: 5000), "any-text-4"]))

        //execute
        let items = try sut.find(storageType: storageType, expression: StorageExpression(constraints: [StorageConstraint(attribute: StorageType.Attribute(name: "name", type: .text, nullable: true), value: nil),
                                                                                                       StorageConstraint(attribute: StorageType.Attribute(name: "anyid", type: .uuid, nullable: false), value: uuidToFind)]))

        //verify
        XCTAssertEqual(items.count, 1)
        XCTAssertEqual(items.first?.values[0] as? UUID, uuidToFind)
        XCTAssertNil(items.first?.values[1] as? String)
    }

    func createConstraintData() throws -> StorageType {
        let storageType = StorageType(name: "simple", attributes: [StorageType.Attribute(name: "any", type: .integer, nullable: false)])
        try sut.createStorageType(storageType: storageType)
        try sut.save(storageType: storageType, item: StorageItem(values: [0]))
        try sut.save(storageType: storageType, item: StorageItem(values: [2]))
        try sut.save(storageType: storageType, item: StorageItem(values: [5]))
        try sut.save(storageType: storageType, item: StorageItem(values: [7]))
        try sut.save(storageType: storageType, item: StorageItem(values: [10]))

        return storageType
    }

    func test_find_constraintOperator_greaterThan_returnsOnlyCorrectResult_andSortsDefaultByCreatedAtASC() throws {
        //prepare
        let storageType = try createConstraintData()

        //execute
        let result = try sut.find(storageType: storageType, expression: StorageExpression(constraints: [StorageConstraint(attribute: storageType.attributes[0], value: 5, constraintOperator: .greaterThan)]))

        //verify
        XCTAssertEqual(result.count, 2)
        XCTAssertEqual(try result[0].value(index: 0) as Int, 7)
        XCTAssertEqual(try result[1].value(index: 0) as Int, 10)
    }

    func test_find_constraintOperator_greaterThan_returnsOnlyCorrectResult_andSortsBySortOrder() throws {
        //prepare
        let storageType = try createConstraintData()

        //execute
        let result = try sut.find(storageType: storageType, expression: StorageExpression(constraints: [StorageConstraint(attribute: storageType.attributes[0], value: 5, constraintOperator: .greaterThan)],
                                                                                          sortedBy: [StorageExpression.SortBy(attribute: storageType.attributes[0], sortOrder: .descending)]))

        //verify
        XCTAssertEqual(result.count, 2)
        XCTAssertEqual(try result[0].value(index: 0) as Int, 10)
        XCTAssertEqual(try result[1].value(index: 0) as Int, 7)
    }

    func test_find_limitsIfLimitIsSet() throws {
        //prepare
        let storageType = try createConstraintData()

        //execute
        let result = try sut.find(storageType: storageType, expression: StorageExpression(constraints: [StorageConstraint(attribute: storageType.attributes[0], value: 5, constraintOperator: .greaterThan)],
                                                                                          sortedBy: [StorageExpression.SortBy(attribute: storageType.attributes[0], sortOrder: .descending)],
                                                                                          limit: StorageExpression.Limit(limit: 1)))

        //verify
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(try result[0].value(index: 0) as Int, 10)
    }

    func test_find_limitsAndStartsAtOffset() throws {
        //prepare
        let storageType = try createConstraintData()

        //execute
        let result = try sut.find(storageType: storageType, expression: StorageExpression(constraints: [StorageConstraint(attribute: storageType.attributes[0], value: 5, constraintOperator: .greaterThan)],
                                                                                          sortedBy: [StorageExpression.SortBy(attribute: storageType.attributes[0], sortOrder: .descending)],
                                                                                          limit: StorageExpression.Limit(limit: 1, offset: 1)))

        //verify
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(try result[0].value(index: 0) as Int, 7)
    }

    func test_find_constraintOperator_greaterThanOrEqual_returnsOnlyCorrectResult() throws {
        //prepare
        let storageType = try createConstraintData()

        //execute
        let result = try sut.find(storageType: storageType, expression: StorageExpression(constraints: [StorageConstraint(attribute: storageType.attributes[0], value: 5, constraintOperator: .greaterThanOrEqual)]))

        //verify
        XCTAssertEqual(result.count, 3)
        XCTAssertEqual(try result[0].value(index: 0) as Int, 5)
        XCTAssertEqual(try result[1].value(index: 0) as Int, 7)
        XCTAssertEqual(try result[2].value(index: 0) as Int, 10)
    }

    func test_find_constraintOperator_lessThan_returnsOnlyCorrectResult() throws {
        //prepare
        let storageType = try createConstraintData()

        //execute
        let result = try sut.find(storageType: storageType, expression: StorageExpression(constraints: [StorageConstraint(attribute: storageType.attributes[0], value: 5, constraintOperator: .lessThan)]))

        //verify
        XCTAssertEqual(result.count, 2)
        XCTAssertEqual(try result[0].value(index: 0) as Int, 0)
        XCTAssertEqual(try result[1].value(index: 0) as Int, 2)
    }

    func test_find_constraintOperator_lessThanOrEqual_returnsOnlyCorrectResult() throws {
        //prepare
        let storageType = try createConstraintData()

        //execute
        let result = try sut.find(storageType: storageType, expression: StorageExpression(constraints: [StorageConstraint(attribute: storageType.attributes[0], value: 5, constraintOperator: .lessThanOrEqual)]))

        //verify
        XCTAssertEqual(result.count, 3)
        XCTAssertEqual(try result[0].value(index: 0) as Int, 0)
        XCTAssertEqual(try result[1].value(index: 0) as Int, 2)
        XCTAssertEqual(try result[2].value(index: 0) as Int, 5)
    }

    func test_count_shouldReturnTheRowCount() throws {
        //prepare
        try sut.createStorageType(storageType: storageType)
        try createRow()
        try createRow()
        try createRow()

        //execute
        let count = try sut.count(storageType: storageType)

        //verify
        XCTAssertEqual(count, 3)
    }

    func test_countConditional_shouldReturnCorrectCount() throws {
        //prepare
        let storageType = try createConstraintData()

        //execute
        let count = try sut.count(storageType: storageType, by: [StorageConstraint(attribute: storageType.attributes[0], value: 5, constraintOperator: .lessThanOrEqual)])

        //verify
        XCTAssertEqual(count, 3)
    }

    func test_removeAttribute_shouldRemoveTheAttribute() throws {
        //prepare
        let helper = try SqliteTestHelper(handle: sut.handle)
        try sut.createStorageType(storageType: storageType)
        let anyId = UUID()
        try sut.save(storageType: storageType, item: StorageItem(values: [anyId, "any-name", true, 42, 500.5, Date(timeIntervalSince1970: 5000), "any-text"]))
        try sut.save(storageType: storageType, item: StorageItem(values: [UUID(), "any-name", true, 42, 500.5, Date(timeIntervalSince1970: 5000), "any-text"]))

        //execute
        guard let nameAttribute = storageType.attributes.first(where: { $0.name == "name" }) else { throw ErrorStub() }
        let actualStorageType = try sut.removeAttribute(storageType: storageType, attribute: nameAttribute, onSchemaVersion: 0)

        //verify
        XCTAssertEqual(actualStorageType.attributes.count, 6)
        XCTAssertNil(actualStorageType.attributes.first { $0.name == "name" })
        XCTAssertEqual(try helper.count(tableName: storageType.name), 2)

        let first = try sut.all(storageType: actualStorageType).first!
        XCTAssertEqual(try first.value(index: 0) as UUID, anyId)
        XCTAssertEqual(try first.value(index: 1) as Bool, true)
        XCTAssertEqual(try first.value(index: 2) as Int, 42)
        XCTAssertEqual(try first.value(index: 3) as Double, 500.5)
        XCTAssertEqual(try first.value(index: 4) as Date, Date(timeIntervalSince1970: 5000))
        XCTAssertEqual(try first.value(index: 5) as String, "any-text")
    }

    func test_removeAttribute_shouldAllowToAddNewRecord() throws {
        //prepare
        let helper = try SqliteTestHelper(handle: sut.handle)
        try sut.createStorageType(storageType: storageType)
        try sut.save(storageType: storageType, item: StorageItem(values: [UUID(), "any-name", true, 42, 500.5, Date(timeIntervalSince1970: 5000), "any-text"]))

        //execute
        guard let nameAttribute = storageType.attributes.first(where: { $0.name == "name" }) else { throw ErrorStub() }
        let actualStorageType = try sut.removeAttribute(storageType: storageType, attribute: nameAttribute, onSchemaVersion: 0)

        let anyId = UUID()
        try sut.save(storageType: actualStorageType, item: StorageItem(values: [anyId, false, 43, 600.6, Date(timeIntervalSince1970: 6000), "any-text-2"]))

        //verify
        XCTAssertEqual(actualStorageType.attributes.count, 6)
        XCTAssertNil(actualStorageType.attributes.first { $0.name == "name" })
        XCTAssertEqual(try helper.count(tableName: storageType.name), 2)

        let first = try sut.all(storageType: actualStorageType).last!
        XCTAssertEqual(try first.value(index: 0) as UUID, anyId)
        XCTAssertEqual(try first.value(index: 1) as Bool, false)
        XCTAssertEqual(try first.value(index: 2) as Int, 43)
        XCTAssertEqual(try first.value(index: 3) as Double, 600.6)
        XCTAssertEqual(try first.value(index: 4) as Date, Date(timeIntervalSince1970: 6000))
        XCTAssertEqual(try first.value(index: 5) as String, "any-text-2")
    }

    func test_removeAttribute_shouldThrowErrorIfSchemaVersionIsNotReached() throws {
        //prepare
        try sut.createStorageType(storageType: storageType)
        guard let nameAttribute = storageType.attributes.first(where: { $0.name == "name" }) else { throw ErrorStub() }

        //execute & verify
        XCTAssertThrowsError(try sut.removeAttribute(storageType: storageType, attribute: nameAttribute, onSchemaVersion: 1))
    }

    func test_removeAttribute_shouldReturnTheNewStorageTypeIfSchemaVersionWasAlreadyReached() throws {
        //prepare
        try sut.createStorageType(storageType: storageType)
        guard let nameAttribute = storageType.attributes.first(where: { $0.name == "name" }) else { throw ErrorStub() }
        _ = try sut.removeAttribute(storageType: storageType, attribute: nameAttribute, onSchemaVersion: 0)
        try sut.incrementStorageTypeVersion(storageType: storageType)

        //execute
        let actualStorageType = try sut.removeAttribute(storageType: storageType, attribute: nameAttribute, onSchemaVersion: 0)
        XCTAssertNil(actualStorageType.attributes.first(where: { $0.name == "name" }))
    }

    func test_addAttribute_shouldThrowErrorIfSchemaVersionIsNotReached() throws {
        //prepare
        try sut.createStorageType(storageType: storageType)
        let newAttribute = StorageType.Attribute(name: "new_attribute", type: .integer, nullable: false)

        //execute & verify
        XCTAssertThrowsError(try sut.addAttribute(storageType: storageType, attribute: newAttribute, defaultValue: 0, onSchemaVersion: 1))
    }

    func test_addAttribute_shouldReturnTheNewStorageTypeIfSchemaVersionWasAlreadyReached() throws {
        //prepare
        try sut.createStorageType(storageType: storageType)
        let newAttribute = StorageType.Attribute(name: "new_attribute", type: .integer, nullable: false)
        _ = try sut.addAttribute(storageType: storageType, attribute: newAttribute, defaultValue: 1, onSchemaVersion: 0)
        try sut.incrementStorageTypeVersion(storageType: storageType)

        //execute
        let actualStorageType = try sut.addAttribute(storageType: storageType, attribute: newAttribute, defaultValue: 0, onSchemaVersion: 0)

        //verify
        XCTAssertNotNil(actualStorageType.attributes.first(where: { $0.name == "new_attribute" }))
    }

    func test_dropTable_shouldDropTheTable() throws {
        //prepare
        let helper = try SqliteTestHelper(handle: sut.handle)
        try sut.createStorageType(storageType: storageType)

        //execute
        try sut.removeStorageType(storageType: storageType)

        //verfiy
        XCTAssertEqual(try helper.existsTable(storageType.name), 0)
    }
}

class SqliteTestHelper {
    var handle: OpaquePointer?

    init(handle: OpaquePointer?) throws {
        self.handle = handle
    }

    func perform(_ statement: String) throws {
        var createTableStatement: OpaquePointer?

        defer {
            sqlite3_finalize(createTableStatement)
        }

        if sqlite3_prepare_v2(handle, statement, -1, &createTableStatement, nil) == SQLITE_OK {
            if sqlite3_step(createTableStatement) == SQLITE_DONE {
                print("Contact table created.")
            } else {
                throw ErrorStub()
            }
        } else {
            throw ErrorStub()
        }
    }

    func existsTable(_ tableName: String) throws -> Int {
        return try count(tableName: "sqlite_master", whereClause: "type='table' AND name='\(tableName)'")
    }

    func count(tableName: String, whereClause: String? = nil) throws -> Int {
        var statement: OpaquePointer?

        defer {
            sqlite3_finalize(statement)
        }

        var select = "SELECT count(*) FROM \(tableName)"
        if let whereClause = whereClause {
            select += " WHERE \(whereClause)"
        }
        select += ";"

        if sqlite3_prepare_v2(handle, select, -1, &statement, nil) == SQLITE_OK {
            if sqlite3_step(statement) == SQLITE_ROW {
                return Int(sqlite3_column_int(statement, 0))
            }
        }
        throw ErrorStub()
    }

    func schemaVersion(name: String) throws -> Int {
        var statement: OpaquePointer?

        defer {
            sqlite3_finalize(statement)
        }

        let select = "SELECT * FROM storage_type_schema_version WHERE name='\(name)';"
        if sqlite3_prepare_v2(handle, select, -1, &statement, nil) == SQLITE_OK {
            if sqlite3_step(statement) == SQLITE_ROW {
                return Int(sqlite3_column_int(statement, 4))
            }
        }
        throw ErrorStub()
    }

    deinit {
        sqlite3_close(handle)
    }
}
