//
//  DateProvider.swift
//  SimpleStorage
//
//  Created by Dominik Gauggel on 30.10.20.
//

import Foundation

public protocol DateProvider {
    var date: Date { get }
}

public class SimpleDateProvider: DateProvider {
    public var date: Date { Date() }
}
