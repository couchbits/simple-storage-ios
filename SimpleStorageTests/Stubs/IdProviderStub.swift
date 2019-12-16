//
//  IdProviderStub.swift
//  StorageTests
//
//  Created by Dominik Gauggel on 11.12.19.
//

import Foundation

class IdProviderStub: IdProvider {
    var id: UUID {
        guard let id = stubbedId else { return UUID() }
        return id
    }
    var stubbedId: UUID?
}
