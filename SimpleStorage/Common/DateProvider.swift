//
//  DateProvider.swift
//  Storage
//
//  Created by Dominik Gauggel on 11/12/19.
//  Copyright © 2019 couchbits GmbH. All rights reserved.
//

import Foundation

public protocol DateProvider {
    var currentDate: Date { get }
}

class DefaultDateProvider {}
extension DefaultDateProvider: DateProvider {
    var currentDate: Date { Date() }
}
