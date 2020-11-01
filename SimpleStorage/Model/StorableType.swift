//
//  StorableType.swift
//  SimpleStorage
//
//  Created by Dominik Gauggel on 31.10.20.
//

import Foundation

public protocol StorableType {}
extension Int: StorableType {}
extension String: StorableType {}
extension UUID: StorableType {}
extension Bool: StorableType {}
extension Double: StorableType {}
extension Date: StorableType {}
