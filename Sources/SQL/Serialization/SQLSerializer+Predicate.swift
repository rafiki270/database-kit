extension SQLSerializer {
    /// See SQLSerializer.serialize(predicateGroup:)
    public func serialize(predicateGroup: DataPredicateGroup) -> String {
        let method = serialize(predicateGroupRelation: predicateGroup.relation)
        let group = predicateGroup.predicates.map(serialize).joined(separator: " \(method) ")
        return "(" + group + ")"
    }

    /// See SQLSerializer.serialize(predicateGroupRelation:)
    public func serialize(predicateGroupRelation: DataPredicateGroupRelation) -> String {
        switch predicateGroupRelation {
        case .and: return "AND"
        case .or: return "OR"
        case .custom(let string): return string
        }
    }

    /// Depending on the predicate item case, calls either:
    ///     - `serialize(predicateGroup:)`
    ///     - `serialize(predicate:)`
    /// This should likely not need to be overridden.
    public func serialize(predicateItem: DataPredicateItem) -> String {
        switch predicateItem {
        case .group(let group): return serialize(predicateGroup: group)
        case .predicate(let predicate): return serialize(predicate: predicate)
        }
    }

    /// See SQLSerializer.serialize(predicate:)
    public func serialize(predicate: DataPredicate) -> String {
        var statement: [String] = []

        let escapedColumn = makeEscapedString(from: predicate.column.name)

        if let table = predicate.column.table {
            let escaped = makeEscapedString(from: table)
            statement.append("\(escaped).\(escapedColumn)")
        } else {
            statement.append(escapedColumn)
        }

        statement.append(serialize(comparison: predicate.comparison))

        switch predicate.comparison {
        case .isNotNull, .isNull:
            // no values should follow IS NULL / IS NOT NULL
            break
        default:
            switch predicate.value {
            case .column(let col):
                statement.append(serialize(column: col))
            case .subquery(let subquery):
                let sub = serialize(data: subquery)
                statement.append("(" + sub + ")")
            case .placeholders(let length):
                if length == 1 {
                    statement.append(makePlaceholder(predicate: predicate))
                } else {
                    var placeholders: [String] = []
                    for _ in 0..<length {
                        placeholders.append(makePlaceholder(predicate: predicate))
                    }
                    statement.append("(" + placeholders.joined(separator: ", ") + ")")
                }
            case .custom(let string): statement.append(string)
            case .none: break
            }
        }

        return statement.joined(separator: " ")
    }

    /// See SQLSerializer.makePlaceholder(predicate:)
    public func makePlaceholder(predicate: DataPredicate) -> String {
        var statement: [String] = []

        switch predicate.comparison {
        case .between:
            statement.append(makePlaceholder(name: predicate.column.name + ".min"))
            statement.append("AND")
            statement.append(makePlaceholder(name: predicate.column.name + ".max"))
        default:
            statement.append(makePlaceholder(name: predicate.column.name))
        }

        return statement.joined(separator: " ")
    }

    /// See SQLSerializer.serialize(comparison:)
    public func serialize(comparison: DataPredicateComparison) -> String {
        switch comparison {
        case .equal: return "="
        case .notEqual: return "!="
        case .lessThan: return "<"
        case .greaterThan: return ">"
        case .lessThanOrEqual: return "<="
        case .greaterThanOrEqual: return ">="
        case .`in`: return "IN"
        case .notIn: return "NOT IN"
        case .between: return "BETWEEN"
        case .like: return "LIKE"
        case .notLike: return "NOT LIKE"
        case .isNull: return "IS NULL"
        case .isNotNull: return "IS NOT NULL"
        case .none: return ""
        case .sql(let sql): return sql
        }
    }
}
