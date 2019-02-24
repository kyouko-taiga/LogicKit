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
    case .val:
      return []
    case ._term(_, let args):
      return args.map({ $0.variables }).reduce(Set<String>(), { $0.union($1) })
    case ._rule(_, let args, let body):
      let subtermVariables = args.map({ $0.variables }).reduce(Set<String>(), { $0.union($1) })
      return body.variables.union(subtermVariables)
    case .conjunction(let lhs, let rhs):
      return lhs.variables.union(rhs.variables)
    case .disjunction(let lhs, let rhs):
      return lhs.variables.union(rhs.variables)
    }
  }

  func renaming(_ variables: Set<String>) -> Term {
    switch self {
    case .var(let x) where variables.contains(x):
      return .var(x + "'")
    case .var, .val:
      return self
    case ._term(let name, let args):
      return ._term(name: name, arguments: args.map({ $0.renaming(variables) }))
    case ._rule(let name, let args, let body):
      return ._rule(
        name: name,
        arguments: args.map({ $0.renaming(variables) }),
        body: body.renaming(variables))
    case .conjunction(let lhs, let rhs):
      return .conjunction(lhs.renaming(variables), rhs.renaming(variables))
    case .disjunction(let lhs, let rhs):
      return .disjunction(lhs.renaming(variables), rhs.renaming(variables))
    }
  }

  // MARK: EDSL

  public static func lit<T>(_ value: T) -> Term where T: Hashable {
    return .val(AnyHashable(value))
  }

  /////

  public static func fact(_ name: Term, _ arguments: Term...) -> Term {
    guard case .val(let val) = name else { fatalError() }
    guard let name = val as? String else { fatalError() }
    return ._term(name: name, arguments: arguments)
  }

  public static func fact(_ name: String, _ arguments: Term...) -> Term {
    return ._term(name: name, arguments: arguments)
  }

  public subscript(terms: Term...) -> Term {
    guard case ._term(let name, let subterms) = self, subterms.isEmpty
      else { fatalError("Cannot coerce '\(self)' into a functor") }
    return ._term(name: name, arguments: terms)
  }

  /////

  public static func rule(_ name: Term, _ arguments: Term..., body: () -> Term) -> Term {
    guard case .val(let val) = name else { fatalError() }
    guard let name = val as? String else { fatalError() }
    return ._rule(name: name, arguments: arguments, body: body())
  }

  public static func rule(_ name: String, _ arguments: Term..., body: () -> Term) -> Term {
    return ._rule(name: name, arguments: arguments, body: body())
  }

  public static func =>(lhs: Term, rhs: Term) -> Term {
    guard case ._term(let name, let args) = rhs
      else { fatalError("Cannot use '\(self)' as a rule head.") }
    return ._rule(name: name, arguments: args, body: lhs)
  }

  public static func |-(lhs: Term, rhs: Term) -> Term {
    guard case ._term(let name, let args) = lhs
      else { fatalError("Cannot use '\(self)' as a rule head.") }
    return ._rule(name: name, arguments: args, body: rhs)
  }

  public static func ⊢(lhs: Term, rhs: Term) -> Term {
    guard case ._term(let name, let args) = lhs
      else { fatalError("Cannot use '\(self)' as a rule head.") }
    return ._rule(name: name, arguments: args, body: rhs)
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
    case .var(let name):
      return "$\(name)"
    case .val(let value):
      return "\(value)"
    case ._term(let name, let args):
      return args.isEmpty
        ? "\(name)"
        : "\(name)[\(args.map({ "\($0)" }).joined(separator: ", "))]"
    case ._rule(let name, let args, let body):
      let head = args.isEmpty
        ? "\(name)"
        : "\(name)[\(args.map({ "\($0)" }).joined(separator: ", "))]"
      return "(\(head) ⊢ \(body))"
    case .conjunction(let lhs, let rhs):
      return "(\(lhs) ∧ \(rhs))"
    case .disjunction(let lhs, let rhs):
      return "(\(lhs) ∨ \(rhs))"
    }
  }

}

extension Term : ExpressibleByStringLiteral {
  public init(stringLiteral : String) {
    self = .fact(stringLiteral)
  }
}
