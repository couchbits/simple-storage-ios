protocol StorageConstraintStringProvider {
    func string(constraint: StorageConstraint) throws -> String
}

class SqliteStorageConstraintStringProvider {
    func checkNumericConstraint(_ constraint: StorageConstraint) throws {
        switch constraint.attribute.type {
        case .uuid, .string, .text, .relationship:
            throw StorageError.invalidData("Operator \(constraint.constraintOperator) is not allowed on character fields")
        case .bool, .integer, .double, .date:
            return
        }
    }
}

extension SqliteStorageConstraintStringProvider: StorageConstraintStringProvider {
    func string(constraint: StorageConstraint) throws -> String {
        if constraint.value == nil {
            if constraint.attribute.nullable {
                if constraint.constraintOperator == .equal {
                    return "\(constraint.attribute.name) IS NULL"
                } else if constraint.constraintOperator == .notEqual {
                    return "\(constraint.attribute.name) IS NOT NULL"
                } else {
                    throw StorageError.invalidData("Attribute \(constraint.attribute.name) nil is only allowed with equals/notEquals")
                }
            } else {
                throw StorageError.invalidData("Attribute \(constraint.attribute.name) is not nullable")
            }
        } else {
            switch constraint.constraintOperator {
            case .equal:
                return "\(constraint.attribute.name) = ?"
            case .notEqual:
                return "\(constraint.attribute.name) != ?"
            case .greaterThan:
                try checkNumericConstraint(constraint)
                return "\(constraint.attribute.name) > ?"
            case .greaterThanOrEqual:
                try checkNumericConstraint(constraint)
                return "\(constraint.attribute.name) >= ?"
            case .lessThan:
                try checkNumericConstraint(constraint)
                return "\(constraint.attribute.name) < ?"
            case .lessThanOrEqual:
                try checkNumericConstraint(constraint)
                return "\(constraint.attribute.name) <= ?"
            }
        }
    }
}
