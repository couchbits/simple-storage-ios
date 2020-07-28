import Foundation

public protocol StorageStorableType {}
extension Int: StorageStorableType {}
extension String: StorageStorableType {}
extension Bool: StorageStorableType {}
extension Double: StorageStorableType {}
extension Date: StorageStorableType {}
extension UUID: StorageStorableType {}
extension Array: StorageStorableType where Element == StorageStorableType {}
