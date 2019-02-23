infix operator ~=~: ComparisonPrecedence
infix operator =>
infix operator |-
infix operator ⊢
infix operator ∧
infix operator ∨

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
    switch dnf {
    case .conjunction(let lhs, let rhs):
      assert((lhs.goals.count == 1) && (rhs.goals.count == 1))
      return [lhs.goals[0] + rhs.goals[0]]
    case .disjunction(let lhs, let rhs):
      return lhs.goals + rhs.goals
    default:
      return [[self]]
    }
  }

  var variables: Set<String> {
    switch self {
    case .var(let x):
      return [x]
    case ._term(name: _, arguments: let subterms):
      return subterms.map({ $0.variables }).reduce(Set<String>(), { $0.union($1) })
    case ._rule(name: _, arguments: let subterms, body: let body):
      let subtermVariables = subterms.map({ $0.variables }).reduce(Set<String>(), { $0.union($1) })
      return body.variables.union(subtermVariables)
    case .conjunction(let lhs, let rhs):
      return lhs.variables.union(rhs.variables)
    case .disjunction(let lhs, let rhs):
      return lhs.variables.union(rhs.variables)
    default:
      return []
    }
  }

  // MARK: EDSL

  public static func lit<T>(_ value: T) -> Term where T: Hashable {
    return .val(AnyHashable(value))
  }

  /////

  public static func fact(_ name: Term, _ arguments: Term...) -> Term {
    guard case let .val(val) = name else { fatalError() }
    guard let name = val as? String else { fatalError() }
    return ._term(name: name, arguments: arguments)
  }

  public static func fact(_ name: String, _ arguments: Term...) -> Term {
    return ._term(name: name, arguments: arguments)
  }

  public subscript(terms: Term...) -> Term {
    guard case let .val(val) = self else { fatalError() }
    guard let name = val as? String else { fatalError() }
    return ._term(name: name, arguments: terms)
  }

  /////

  public static func rule(_ name: Term, _ arguments: Term..., body: () -> Term) -> Term {
    guard case let .val(val) = name else { fatalError() }
    guard let name = val as? String else { fatalError() }
    return ._rule(name: name, arguments: arguments, body: body())
  }

  public static func rule(_ name: String, _ arguments: Term..., body: () -> Term) -> Term {
    return ._rule(name: name, arguments: arguments, body: body())
  }

  public static func =>(lhs: Term, rhs: Term) -> Term {
    guard case let ._term(name: name, arguments: arguments) = rhs else { fatalError() }
    return ._rule(name: name, arguments: arguments, body: lhs)
  }

  public static func =>(lhs: () -> Term, rhs: Term) -> Term {
    guard case let ._term(name: name, arguments: arguments) = rhs else { fatalError() }
    return ._rule(name: name, arguments: arguments, body: lhs())
  }

  public static func |-(lhs: Term, rhs: Term) -> Term {
    guard case let ._term(name: name, arguments: arguments) = lhs else { fatalError() }
    return ._rule(name: name, arguments: arguments, body: rhs)
  }

  public static func |-(lhs: Term, rhs: () -> Term) -> Term {
    guard case let ._term(name: name, arguments: arguments) = lhs else { fatalError() }
    return ._rule(name: name, arguments: arguments, body: rhs())
  }

  public static func ⊢(lhs: Term, rhs: Term) -> Term {
    guard case let ._term(name: name, arguments: arguments) = lhs else { fatalError() }
    return ._rule(name: name, arguments: arguments, body: rhs)
  }

  public static func ⊢(lhs: Term, rhs: () -> Term) -> Term {
    guard case let ._term(name: name, arguments: arguments) = lhs else { fatalError() }
    return ._rule(name: name, arguments: arguments, body: rhs())
  }

  /////

  public static func &&(lhs: Term, rhs: Term) -> Term {
    return .conjunction(lhs, rhs)
  }

  public static func ∧(lhs: Term, rhs: Term) -> Term {
    return .conjunction(lhs, rhs)
  }

  /////

  public static func ||(lhs: Term, rhs: Term) -> Term {
    return .disjunction(lhs, rhs)
  }

  public static func ∨(lhs: Term, rhs: Term) -> Term {
    return .disjunction(lhs, rhs)
  }

  /////

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
        ? name.description
        : "\(name)[\(arguments.map({ $0.description }).joined(separator: ", "))]"
    case let ._rule(name, arguments, body):
      let head = arguments.isEmpty
        ? name.description
        : "\(name)[\(arguments.map({ $0.description }).joined(separator: ", "))]"
      return "(\(head) ⊢ \(body))"
    case let .conjunction(lhs, rhs):
      return "(\(lhs) ∧ \(rhs))"
    case let .disjunction(lhs, rhs):
      return "(\(lhs) ∨ \(rhs))"
    }
  }

}

extension Term : ExpressibleByStringLiteral {
  public init(stringLiteral : String) {
    self = .lit(stringLiteral)
  }
}
