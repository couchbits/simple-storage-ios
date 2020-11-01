//
//  SimpleStorageDelete.swift
//  SimpleStorage
//
//  Created by Dominik Gauggel on 01.11.20.
//

import Foundation

extension SimpleStorage {
    func delete(storageType: String, id: UUID) throws {
        try delete(storageType: storageType, constraints: [Constraint(attribute: "id", value: id)])
    }

    func delete(storageType: String, constraints: [Constraint] = []) throws {
        try syncRunner.run {
            var sql = "DELETE FROM \(storageType)"

            let tableDescription = try self.tableDescription(storageType)
            if let whereClause = try createConstraints(constraints: constraints, tableDescription: tableDescription) {
                sql += " \(whereClause)"
            }

            let statement = try sqlite.prepareStatement(sql: sql)
            try bindConstraints(constraints, tableDescription: tableDescription, statement: statement)

            try sqlite.performStatement(statement: statement)
        }
    }
}
