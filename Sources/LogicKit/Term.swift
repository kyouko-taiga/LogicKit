infix operator ~=~: ComparisonPrecedence

public enum Term {

    case `var`(String)
    case val(AnyHashable)
    indirect case _term(name: String, arguments: [Term])
    indirect case _rule(name: String, arguments: [Term], body: Term)

    indirect case conjunction(Term, Term)
    indirect case disjunction(Term, Term)

    var dnf: Term {
        switch self {
        case .conjunction(let a, .disjunction(let b, let c)):
            return (a && b) || (a && c)
        case .conjunction(.disjunction(let a, let b), let c):
            return (a && c) || (b && c)
        default:
            return self
        }
    }

    var goals: [[Term]] {
        switch self.dnf {
        case .conjunction(let lhs, let rhs):
            assert((lhs.goals.count == 1) && (rhs.goals.count == 1))
            return [lhs.goals[0] + rhs.goals[0]]
        case .disjunction(let lhs, let rhs):
            return lhs.goals + rhs.goals
        default:
            return [[self]]
        }
    }

    // MARK: EDSL

    public static func lit<T>(_ value: T) -> Term where T: Hashable {
        return .val(AnyHashable(value))
    }

    public static func fact(_ name: String, _ arguments: Term...) -> Term {
        return ._term(name: name, arguments: arguments)
    }

    public static func rule(_ name: String, _ arguments: Term..., body: () -> Term) -> Term {
        return ._rule(name: name, arguments: arguments, body: body())
    }

    public static func &&(lhs: Term, rhs: Term) -> Term {
        return .conjunction(lhs, rhs)
    }

    public static func ||(lhs: Term, rhs: Term) -> Term {
        return .disjunction(lhs, rhs)
    }

    public static func ~=~(lhs: Term, rhs: Term) -> Term {
        return ._term(name: "lk.~=~", arguments: [lhs, rhs])
    }

}

extension Term: Hashable {
}

extension Term: CustomStringConvertible {

    public var description: String {
        switch self {
        case let .var(name):
            return "$\(name)"
        case let .val(value):
            return "\(value)"
        case let ._term(name, arguments):
            return arguments.isEmpty
                ? name
                : "\(name)(\(arguments.map({ $0.description }).joined(separator: ", ")))"
        case let ._rule(name, arguments, body):
            let head = arguments.isEmpty
                ? name
                : "\(name)(\(arguments.map({ $0.description }).joined(separator: ", ")))"
            return "(\(head) :- \(body))"
        case let .conjunction(lhs, rhs):
            return "(\(lhs) ∧ \(rhs))"
        case let .disjunction(lhs, rhs):
            return "(\(lhs) ∨ \(rhs))"
        }
    }

}
