import LogicKit

public enum List {

  // MARK: Generators

  public static let empty: Term = .lit("list::empty")

  public static func cons(_ head: Term, _ tail: Term) -> Term {
    guard isList(tail)
      else { fatalError("'\(tail)' is not a list") }
    return .fact("list::cons", head, tail)
  }

  // MARK: Predicates

  public static func count(list: Term, count: Term) -> Term {
    assert(isList(list), "'\(list)' is not a builtin list")

    return .fact("list::count", list, count)
  }

  public static func contains(list: Term, element: Term) -> Term {
    assert(isList(list), "'\(list)' is not a builtin list")

    return .fact("list::contains", list, element)
  }

  public static func concat(_ lhs: Term, _ rhs: Term, _ res: Term) -> Term {
    assert(isList(lhs), "'\(lhs)' is not a builtin list")
    assert(isList(rhs), "'\(rhs)' is not a builtin list")
    assert(isList(res), "'\(res)' is not a builtin list")

    return .fact("list::concat", lhs, rhs, res)
  }

  // MARK: Axioms

  public static var axioms: [Term] { return countAxioms + containsAxioms + concatAxioms }

  public static let countAxioms: [Term] = {
    let a: Term = .var("a")
    let b: Term = .var("b")
    let c: Term = .var("c")

    return [
      .fact("list::count", empty, Nat.zero),
      .rule("list::count", cons(a, b), Nat.succ(c)) {
        .fact("list::count", b, c)
      },
    ]
  }()

  public static let containsAxioms: [Term] = {
    let a: Term = .var("a")
    let b: Term = .var("b")
    let c: Term = .var("c")

    return [
      .fact("list::contains", cons(a, b), a),
      .rule("list::contains", cons(a, b), c) {
        .fact("list::contains", b, c)
      },
    ]
  }()

  public static let concatAxioms: [Term] = {
    let a: Term = .var("a")
    let b: Term = .var("b")
    let c: Term = .var("c")
    let d: Term = .var("d")

    return [
      .fact("list::concat", empty, a, a),
      .fact("list::concat", a, empty, a),
      .rule("list::concat", cons(a, b), c, cons(a, d)) {
        .fact("list::concat", b, c, d)
      },
    ]
  }()

  // MARK: Helpers

  public static func from<C>(elements: C) -> Term where C: Collection, C.Element == Term {
    return !elements.isEmpty
      ? cons(elements.first!, from(elements: elements.dropFirst()))
      : empty
  }

  public static func isList(_ t: Term) -> Bool {
    switch t {
    case .var, empty:
      return true
    case ._term("list::cons", let args):
      return args.count == 2 && isList(args[1])
    default:
      return false
    }
  }

}
