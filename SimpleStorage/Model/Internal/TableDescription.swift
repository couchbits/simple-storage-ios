//
//  TableDescription.swift
//  SimpleStorage
//
//  Created by Dominik Gauggel on 01.11.20.
//

import Foundation

struct TableDescription: Equatable {
    let name: String
    let columns: [Column]

    struct Column: Equatable {
        let name: String
        let type: ColumnType
        let nullable: Bool

        enum ColumnType: Equatable {
            case integer
            case text
            case real
        }
    }
}
