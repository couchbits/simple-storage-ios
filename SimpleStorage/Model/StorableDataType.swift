//
//  StorableType.swift
//  SimpleStorage
//
//  Created by Dominik Gauggel on 31.10.20.
//

import Foundation

public protocol StorableDataType {}
extension Int: StorableDataType {}
extension String: StorableDataType {}
extension UUID: StorableDataType {}
extension Bool: StorableDataType {}
extension Double: StorableDataType {}
extension Date: StorableDataType {}
