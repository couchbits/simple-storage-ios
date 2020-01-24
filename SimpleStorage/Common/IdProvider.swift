//
//  IdProvider.swift
//  Storage
//
//  Created by Dominik Gauggel on 11/12/19.
//  Copyright © 2019 couchbits GmbH. All rights reserved.
//

import Foundation

public protocol IdProvider {
    var id: UUID { get }
}

extension UUID {
    var idString: String { return uuidString.lowercased() }
}

class DefaultIdProvider {}
extension DefaultIdProvider: IdProvider {
    var id: UUID { return UUID() }
}
