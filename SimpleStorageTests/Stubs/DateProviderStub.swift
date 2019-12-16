//
//  DateProviderStub.swift
//  StorageTests
//
//  Created by Dominik Gauggel on 11.12.19.
//

import Foundation

class DateProviderStub: DateProvider {
    var currentDate: Date {
        guard let date = stubbedDate else { return Date() }
        return date
    }
    var stubbedDate: Date?
}
