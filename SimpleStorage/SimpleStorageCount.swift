//
//  SimpleStorageCount.swift
//  SimpleStorage
//
//  Created by Dominik Gauggel on 01.11.20.
//

import Foundation

extension SimpleStorage {
    public func count(storageType: String, constraints: [Constraint] = []) throws -> Int {
        var sql = "SELECT COUNT(*) FROM \(storageType)"

        let tableDescription = try self.tableDescription(storageType)
        if let whereClause = try createConstraints(constraints: constraints, tableDescription: tableDescription) {
            sql += " \(whereClause)"
        }

        let statement = try sqlite.prepareStatement(sql: sql)
        try bindConstraints(constraints, tableDescription: tableDescription, statement: statement)

        return try sqlite.performCountStatement(statement)
    }
}
