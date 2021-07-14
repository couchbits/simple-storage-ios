//
//  SimpleStorage.swift
//  SimpleStorage
//
//  Created by Dominik Gauggel on 30.10.20.
//

import Foundation
import SQLite3

public class SimpleStorage {
    let dateProvider: DateProvider
    let sqlite: Sqlite
    let syncRunner = DefaultSyncRunner()

    public init(configuration: SimpleStorageConfiguration) throws {
        dateProvider = configuration.dateProvider
        switch configuration.type {
        case .inMemory:
            sqlite = try Sqlite(path: ":memory:", printSql: configuration.printSql)
        case .file(let url):
            sqlite = try Sqlite(path: url.path, printSql: configuration.printSql)
        }

        try createStorageType(storageType: "storage_type_versions")
        if try storageTypeVersion(storageType: "storage_type_versions") == 0 {
            try addAttribute(
                storageType: "storage_type_versions",
                attribute: Attribute(name: "storage_type", type: .string, nullable: false)
            )

            try addAttribute(
                storageType: "storage_type_versions",
                attribute: Attribute(name: "version", type: .integer, nullable: false)
            )

            try setStorageTypeVersion(storageType: "storage_type_versions", version: 1)
        }
    }

    func createConstraints(constraints: [Constraint], tableDescription: TableDescription) throws -> String? {
        guard constraints.count > 0 else { return nil}
        let constraints = try constraints
            .map { try createConstraint(tableDescription: tableDescription, constraint: $0) }
            .joined(separator: " AND ")
        return "WHERE \(constraints)"
    }

    func createConstraint(tableDescription: TableDescription, constraint: Constraint) throws -> String {
        guard let column = tableDescription.columns.first(where: { $0.name == constraint.attribute }) else {
            throw SimpleStorageError.invalidDefinition("\(tableDescription.name) didn't have an attribute \(constraint.attribute)")
        }

        if constraint.value != nil {
            switch constraint.operator {
            case .equal:
                return "\(constraint.attribute) = ?"
            case .notEqual:
                return "\(constraint.attribute) != ?"
            case .greaterThan:
                try checkConstraintNumeric(column, operator: constraint.operator)
                return "\(constraint.attribute) > ?"
            case .greaterThanOrEqual:
                try checkConstraintNumeric(column, operator: constraint.operator)
                return "\(constraint.attribute) >= ?"
            case .lessThan:
                try checkConstraintNumeric(column, operator: constraint.operator)
                return "\(constraint.attribute) < ?"
            case .lessThanOrEqual:
                try checkConstraintNumeric(column, operator: constraint.operator)
                return "\(constraint.attribute) <= ?"
            }
        } else {
            if column.nullable {
                if constraint.operator == .equal {
                    return "\(constraint.attribute) IS NULL"
                } else if constraint.operator == .notEqual {
                    return "\(constraint.attribute) IS NOT NULL"
                } else {
                    throw SimpleStorageError.invalidData("Attribute \(constraint.attribute) nil is only allowed with equal/notEqual")
                }
            } else {
                throw SimpleStorageError.invalidData("Attribute \(constraint.attribute) is not nullable")
            }
        }
    }

    func bindConstraints(_ constraints: [Constraint], tableDescription: TableDescription, statement: OpaquePointer?) throws {
        var columnValues = [(column: TableDescription.Column, value: StorableDataType?)]()
        for constraint in constraints {
            guard let column = tableDescription.columns.first(where: { $0.name == constraint.attribute }) else { continue }
            columnValues.append((column: column, value: constraint.value))
        }
        
        try bindValues(columnValues: columnValues, statement: statement)
    }

    func checkConstraintNumeric(_ column: TableDescription.Column, operator: Constraint.Operator) throws {
        switch column.type {
        case .text:
            throw SimpleStorageError.invalidData("Operator \(`operator`) is not allowed on character fields")
        case .integer, .real:
            return
        }
    }
}
