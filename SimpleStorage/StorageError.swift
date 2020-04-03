//
//  StorageError.swift
//  Storage
//
//  Created by Dominik Gauggel on 11/12/19.
//  Copyright © 2019 couchbits GmbH. All rights reserved.
//

import Foundation

public enum StorageError: Error {
    case open(String)
    case invalidDefinition(String)
    case perform(String)
    case prepareStatement(String)
    case invalidData(String)
    case notFound(String)
    case migrationFailed(String)
    case fatal(message: String, error: Error)
    case unexpected
}
