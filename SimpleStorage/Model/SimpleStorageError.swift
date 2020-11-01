//
//  SimpleStorageError.swift
//  SimpleStorage
//
//  Created by Dominik Gauggel on 30.10.20.
//

import Foundation

public enum SimpleStorageError: Error {
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
