public enum Term {

  /// A logic variable.
  case `var`(String)

  /// A literal (Swift) value.
  case val(AnyHashable)

  /// A fact.
  indirect case _term(name: String, arguments: [Term])

  /// A rule.
  indirect case _rule(name: String, arguments: [Term], body: Term)

  /// A conjunction of terms.
  indirect case conjunction(Term, Term)

  /// A disjunction of terms.
  indirect case disjunction(Term, Term)

  /// A Swift predicate.
  case native(([String: Term]) -> Bool)

  /// The DNF form of this term.
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

  /// The goals to satisfy in this term.
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

  /// The free variables occurring in this term.
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

    case .native:
      return []
    }
  }

  /// Returns an alpha-equivalent term in which all given variables have been renamed.
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

    case .native:
      return self
    }
  }

}

extension Term: Hashable {

  public func hash(into hasher: inout Hasher) {
    switch self {
    case .var(let name):
      hasher.combine(name)

    case .val(let value):
      hasher.combine(value)

    case ._term(let name, let args):
      hasher.combine(name)
      hasher.combine(args)

    case ._rule(let name, let args, let body):
      hasher.combine(name)
      hasher.combine(args)
      hasher.combine(body)
      
    case .conjunction(let lhs, let rhs):
      hasher.combine(lhs)
      hasher.combine(rhs)

    case .disjunction(let lhs, let rhs):
      hasher.combine(lhs)
      hasher.combine(rhs)

    case .native:
      hasher.combine(0)
    }
  }

  public static func == (lhs: Term, rhs: Term) -> Bool {
    switch (lhs, rhs) {
    case (.var(let lname), .var(let rname)):
      return lname == rname

    case (.val(let lvalue), .val(let rvalue)):
      return lvalue == rvalue

    case (._term(let lname, let largs), ._term(let rname, let rargs)):
      return (lname == rname) && (largs == rargs)

    case (._rule(let lname, let largs, let lbody), ._rule(let rname, let rargs, let rbody)):
      return (lname == rname) && (largs == rargs) && (lbody == rbody)

    case (.conjunction(let ll, let lr), .conjunction(let rl, let rr)):
      return ll == rl && lr == rr

    case (.disjunction(let ll, let lr), .disjunction(let rl, let rr)):
      return ll == rl && lr == rr

    default:
      return false
    }
  }

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
    case .native:
      return "(SwiftPredicate)"
    }
  }

}
