import LogicKit

public enum Nat {

  // MARK: Generators

  public static let zero: Term = .lit("nat::0")

  public static func succ(_ n: Term) -> Term {
    assert(isNat(n), "'\(n)' is not a builtin natural number")
    return .fact("nat::succ", n)
  }

  // MARK: Predicates

  public static func greater(_ lhs: Term, _ rhs: Term) -> Term {
    assert(isNat(lhs), "'\(lhs)' is not a builtin natural number")
    assert(isNat(rhs), "'\(rhs)' is not a builtin natural number")

    return .fact("nat::>", lhs, rhs)
  }

  public static func greaterOrEqual(_ lhs: Term, _ rhs: Term) -> Term {
    assert(isNat(lhs), "'\(lhs)' is not a builtin natural number")
    assert(isNat(rhs), "'\(rhs)' is not a builtin natural number")

    return .fact("nat::>=", lhs, rhs)
  }

  public static func smaller(_ lhs: Term, _ rhs: Term) -> Term {
    assert(isNat(lhs), "'\(lhs)' is not a builtin natural number")
    assert(isNat(rhs), "'\(rhs)' is not a builtin natural number")

    return .fact("nat::<", lhs, rhs)
  }

  public static func smallerOrEqual(_ lhs: Term, _ rhs: Term) -> Term {
    assert(isNat(lhs), "'\(lhs)' is not a builtin natural number")
    assert(isNat(rhs), "'\(rhs)' is not a builtin natural number")

    return .fact("nat::<=", lhs, rhs)
  }

  public static func add(_ lhs: Term, _ rhs: Term, _ res: Term) -> Term {
    assert(isNat(lhs), "'\(lhs)' is not a builtin natural number")
    assert(isNat(lhs), "'\(lhs)' is not a builtin natural number")
    assert(isNat(res), "'\(res)' is not a builtin natural number")

    return .fact("nat::+", lhs, rhs, res)
  }

  public static func sub(_ lhs: Term, _ rhs: Term, _ res: Term) -> Term {
    assert(isNat(lhs), "'\(lhs)' is not a builtin natural number")
    assert(isNat(lhs), "'\(lhs)' is not a builtin natural number")
    assert(isNat(res), "'\(res)' is not a builtin natural number")

    return .fact("nat::-", lhs, rhs, res)
  }

  public static func mul(_ lhs: Term, _ rhs: Term, _ res: Term) -> Term {
    assert(isNat(lhs), "'\(lhs)' is not a builtin natural number")
    assert(isNat(lhs), "'\(lhs)' is not a builtin natural number")
    assert(isNat(res), "'\(res)' is not a builtin natural number")

    return .fact("nat::*", lhs, rhs, res)
  }

  public static func div(_ lhs: Term, _ rhs: Term, _ res: Term) -> Term {
    assert(isNat(lhs), "'\(lhs)' is not a builtin natural number")
    assert(isNat(lhs), "'\(lhs)' is not a builtin natural number")
    assert(isNat(res), "'\(res)' is not a builtin natural number")

    return .fact("nat::/", lhs, rhs, res)
  }

  public static func mod(_ lhs: Term, _ rhs: Term, _ res: Term) -> Term {
    assert(isNat(lhs), "'\(lhs)' is not a builtin natural number")
    assert(isNat(lhs), "'\(lhs)' is not a builtin natural number")
    assert(isNat(res), "'\(res)' is not a builtin natural number")

    return .fact("nat::%", lhs, rhs, res)
  }

  // MARK: Axioms

  public static var axioms: [Term] { return arithmeticAxioms }

  public static let relationAxioms: [Term] = {
    let x: Term = .var("x")
    let y: Term = .var("y")

    return [
      .fact("nat::>", succ(x), zero),
      .rule("nat::>", succ(x), succ(y)) {
        greater(x, y)
      },

      .fact("nat::>=", x, x),
      .rule("nat::>=", x, y) {
        greater(x, y)
      },

      .fact("nat::<", zero, succ(x)),
      .rule("nat::<", succ(x), succ(y)) {
        smaller(x, y)
      },

      .fact("nat::<=", x, x),
      .rule("nat::<=", x, y) {
        smaller(x, y)
      },
    ]
  }()

  public static let arithmeticAxioms: [Term] = {
    let v: Term = .var("v")
    let w: Term = .var("w")
    let x: Term = .var("x")
    let y: Term = .var("y")
    let z: Term = .var("z")

    return relationAxioms + [
      .fact("nat::+", zero, y, y),
      .rule("nat::+", succ(x), y, z) {
        add(x, succ(y), z)
      },

      .fact("nat::-", x, zero, x),
      .rule("nat::-", succ(x), succ(y), z) {
        sub(x, y, z)
      },

      .fact("nat::*", zero, y, zero),
      .rule("nat::*", succ(x), y, z) {
        mul(x, y, w) && add(w, y, z)
      },

      .rule("nat::/", x, y, zero) {
        smaller(x, y)
      },
      .rule("nat::/", x, succ(y), succ(z)) {
        sub(x, succ(y), w) && div(w, succ(y), z)
      },

      .rule("nat::%", x, succ(y), z) {
        div(x, succ(y), w) && mul(succ(y), w, v) && sub(x, v, z)
      }
    ]
  }()

  // MARK: Helpers

  public static func from(_ i: Int) -> Term {
    return i > 0
      ? succ(from(i - 1))
      : zero
  }

  public static func asSwiftInt(_ t: Term) -> Int? {
    switch t {
    case zero:
      return 0
    case ._term("nat::succ", let u):
      if let n = asSwiftInt(u.first!) {
        return n + 1
      } else {
        return nil
      }
    default:
      return nil
    }
  }

  public static func isNat(_ t: Term) -> Bool {
    switch t {
    case .var, zero:
      return true
    case ._term("nat::succ", let n):
      return n.count == 1 && isNat(n[0])
    default:
      return false
    }
  }

}
