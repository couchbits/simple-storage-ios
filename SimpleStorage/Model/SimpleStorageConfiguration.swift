//
//  SimpleStorageConfiguration.swift
//  SimpleStorage
//
//  Created by Dominik Gauggel on 30.10.20.
//

import Foundation

public struct SimpleStorageConfiguration {
    public var type: SimpleStorageType = .inMemory
    public var transactional: Bool = true
    public var dateProvider: DateProvider = SimpleDateProvider()

    public enum SimpleStorageType {
        case inMemory
        case file(url: URL)
    }

    public static var `defaultInMemory`: SimpleStorageConfiguration {
        return SimpleStorageConfiguration()
    }

    public static func `default`(url: URL) -> SimpleStorageConfiguration {
        var configuration = SimpleStorageConfiguration()
        configuration.type = .file(url: url)
        return configuration
    }
}
