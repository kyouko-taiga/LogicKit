infix operator ~=~: ComparisonPrecedence
infix operator => : AssignmentPrecedence
infix operator |- : AssignmentPrecedence
infix operator ⊢  : AssignmentPrecedence
infix operator ∧  : LogicalConjunctionPrecedence
infix operator ∨  : LogicalDisjunctionPrecedence

extension Term {

  public static func lit<T>(_ value: T) -> Term where T: Hashable {
    return .val(AnyHashable(value))
  }

  public func extractValue<T>(ofType type: T.Type) -> T? {
    guard case .val(let v) = self
      else { return nil }
    return v as? T
  }

  public static func fact(_ name: String, _ arguments: Term...) -> Term {
    return ._term(name: name, arguments: arguments)
  }

  public subscript(terms: Term...) -> Term {
    guard case ._term(let name, let subterms) = self, subterms.isEmpty
      else { fatalError("Cannot coerce '\(self)' into a functor") }
    return ._term(name: name, arguments: terms)
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

  public static func &&(lhs: Term, rhs: Term) -> Term {
    return .conjunction(lhs, rhs)
  }

  public static func ∧(lhs: Term, rhs: Term) -> Term {
    return .conjunction(lhs, rhs)
  }

  public static func ||(lhs: Term, rhs: Term) -> Term {
    return .disjunction(lhs, rhs)
  }

  public static func ∨(lhs: Term, rhs: Term) -> Term {
    return .disjunction(lhs, rhs)
  }

  public static func ~=~(lhs: Term, rhs: Term) -> Term {
    return ._term(name: "lk.~=~", arguments: [lhs, rhs])
  }

}

protocol PredicateConvertible {

  var name: String { get }
  var arguments: [PredicateConvertible] { get }

}

extension PredicateConvertible {

  var predicateValue: Term {
    return ._term(name: name, arguments: arguments.map({ $0.predicateValue }))
  }

}

extension Term: PredicateConvertible {

  var name: String {
    guard case ._term(let name, _) = self
      else { fatalError() }
    return name
  }

  var arguments: [PredicateConvertible] {
    guard case ._term(_, let arguments) = self
      else { fatalError() }
    return arguments
  }

}


@dynamicCallable
public struct Functor {

  public let name: String
  public let arity: Int

  public func dynamicallyCall(withArguments args: [Term]) -> Term {
    assert(args.count == arity)
    return ._term(name: name, arguments: args)
  }

  public func dynamicallyCall(withArguments args: [Any]) -> Term {
    assert(args.count == arity)
    return ._term(
      name: name,
      arguments: args.map({ (arg: Any) -> Term in
        switch arg {
        case let term as Term:
          return term
        case let value as AnyHashable:
          return .lit(value)
        default:
          fatalError("'\(arg)' is not a valid term argument")
        }
      }))
  }

}

public func / (name: String, arity: Int) -> Functor {
  return Functor(name: name, arity: arity)
}
