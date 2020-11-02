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
            sqlite = try Sqlite(path: ":memory:")
        case .file(let url):
            sqlite = try Sqlite(path: url.path)
        }

        try createStorageType(storageType: "storage_type_versions")
        if try storageTypeVersion(storageType: "storage_type_versions") == 0 {
            try addStorageTypeAttribute(
                storageType: "storage_type_versions",
                attribute: Attribute(name: "storage_type", type: .string, nullable: false)
            )

            try addStorageTypeAttribute(
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
                try checkConstraintNumeric(column, constraintOperator: constraint.operator)
                return "\(constraint.attribute) > ?"
            case .greaterThanOrEqual:
                try checkConstraintNumeric(column, constraintOperator: constraint.operator)
                return "\(constraint.attribute) >= ?"
            case .lessThan:
                try checkConstraintNumeric(column, constraintOperator: constraint.operator)
                return "\(constraint.attribute) < ?"
            case .lessThanOrEqual:
                try checkConstraintNumeric(column, constraintOperator: constraint.operator)
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
        let constraints = constraints.filter { $0.value != nil }
        var columns = [TableDescription.Column?]()
        var values = [String: StorableType]()
        for constraint in constraints {
            values[constraint.attribute] = constraint.value
            columns.append(tableDescription.columns.first { $0.name == constraint.attribute })
        }
        try bindValues(columns: columns.compactMap { $0 }, values: values, statement: statement)
    }

    func checkConstraintNumeric(_ column: TableDescription.Column, constraintOperator: Constraint.Operator) throws {
        switch column.type {
        case .text:
            throw SimpleStorageError.invalidData("Operator \(constraintOperator) is not allowed on character fields")
        case .integer, .real:
            return
        }
    }
}
