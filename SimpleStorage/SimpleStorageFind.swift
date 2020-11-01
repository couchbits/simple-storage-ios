//
//  SimpleStorageFind.swift
//  SimpleStorage
//
//  Created by Dominik Gauggel on 31.10.20.
//

import Foundation
import SQLite3

extension SimpleStorage {
    public func find(storageType: String, id: UUID) throws -> Item? {
        let expression = Expression(
            constraints: [Constraint(attribute: "id", value: id)],
            limit: Expression.Limit(limit: 1)
        )
        return try find(storageType: storageType, expression: expression).first
    }

    public func find(storageType: String, expression: Expression = .empty) throws -> [Item] {
        let tableDescription = try self.tableDescription(storageType)

        let namesString = tableDescription.columns.map { $0.name }.joined(separator: ", ")
        var select = "SELECT \(namesString) FROM \(storageType)"

        if let whereClause = try createConstraints(constraints: expression.constraints, tableDescription: tableDescription) {
            select += " \(whereClause)"
        }

        select += " \(createSortBy(expression.sortedBy))"
        if let limit = expression.limit {
            select += " LIMIT \(limit.limit)"
            if let offset = limit.offset {
                select += " OFFSET \(offset)"
            }
        }

        let statement = try sqlite.prepareStatement(sql: select)

        defer {
            sqlite3_finalize(statement)
        }

        try bindConstraints(expression.constraints, tableDescription: tableDescription, statement: statement)

        return try read(tableDescription: tableDescription, statement: statement)
    }

    private func read(tableDescription: TableDescription, statement: OpaquePointer?) throws -> [Item] {
        var items = [Item]()

        while sqlite3_step(statement) == SQLITE_ROW {
            var values = [String: StorableType]()
            for (index, column) in tableDescription.columns.enumerated() {
                switch column.type {
                case .integer:
                    values[column.name] = try readInteger(statement: statement, index: index, nullable: column.nullable)
                case .text:
                    values[column.name] = try readString(statement: statement, index: index, nullable: column.nullable)
                case .real:
                    values[column.name] = try readDouble(statement: statement, index: index, nullable: column.nullable)
                }
            }
            guard let idString = values["id"] as? String, let id = UUID(uuidString: idString) else {
                throw SimpleStorageError.invalidData("Didn't have an ID")
            }

            items.append(Item(id: id, values: values))
        }

        return items
    }

    private func value(_ sortOrder: Expression.SortBy.SortOrder) -> String {
        switch sortOrder {
        case .ascending:
            return "ASC"
        case .descending:
            return "DESC"
        }
    }

    private func createSortBy(_ sortBys: [Expression.SortBy]) -> String {
        var sortBys = sortBys
        if !sortBys.contains(where: { $0.attribute == "created_at" }) {
            sortBys += [Expression.SortBy(attribute: "created_at", sortOrder: .ascending)]
        }
        return "ORDER BY \(sortBys.map { "\($0.attribute) \(value($0.sortOrder))"}.joined(separator: ", "))"
    }

    func readString(statement: OpaquePointer?, index: Int, nullable: Bool) throws -> String? {
        let columnType = sqlite3_column_type(statement, Int32(index))
        if columnType == SQLITE_TEXT {
            return String(cString: sqlite3_column_text(statement, Int32(index)))
        } else if nullable && columnType == SQLITE_NULL {
            return nil
        } else {
            throw SimpleStorageError.invalidData("Value is null or not a string")
        }
    }

    func readDouble(statement: OpaquePointer?, index: Int, nullable: Bool) throws -> Double? {
        let columnType = sqlite3_column_type(statement, Int32(index))
        if columnType == SQLITE_FLOAT {
            return sqlite3_column_double(statement, Int32(index))
        } else if nullable && columnType == SQLITE_NULL {
            return nil
        } else {
            throw SimpleStorageError.invalidData("Value is null or a double")
        }
    }

    func readInteger(statement: OpaquePointer?, index: Int, nullable: Bool) throws -> Int? {
        let columnType = sqlite3_column_type(statement, Int32(index))
        if columnType == SQLITE_INTEGER {
            return Int(sqlite3_column_int64(statement, Int32(index)))
        } else if nullable && columnType == SQLITE_NULL {
            return nil
        } else {
            throw SimpleStorageError.invalidData("Value is null or not an integer")
        }
    }
}
