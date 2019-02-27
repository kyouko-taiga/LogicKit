import LogicKit
import LogicKitBuiltins

// Syntax sugars

prefix operator %
prefix func %(name: String) -> Term {
  return .var(name)
}

// Term constructors

func pair(_ fst: Term, _ snd: Term) -> Term {
  return .fact("pair", fst, snd)
}

func value(in mapping: Term, for key: Term, is val: Term) -> Term {
  return .fact("value(in:for:is:)", mapping, key, val)
}

func λ(_ x: Term, _ body: Term) -> Term {
  return .fact("λ", x, body)
}

func app(_ a: Term, _ b: Term) -> Term {
  return .fact("app", a, b)
}

func type(knowing Γ: Term, of a: Term, is t: Term) -> Term {
  return .fact("type(knowing:of:is:)", Γ, a, t)
}

// Knowledge base

let kb = KnowledgeBase(knowledge: [

  // Deduction rules for `value(in:for:is:)`.

  .fact("value(in:for:is:)", List.cons(pair(%"key", %"val"), %"tail"), %"key", %"val"),
  .rule("value(in:for:is:)", List.cons(%"h", %"tail"), %"key", %"val") {
    .fact("value(in:for:is:)", %"tail", %"key", %"val")
  },

  // Hindley-Milner

  // Var
  .rule("type(knowing:of:is:)", %"Γ", %"x", %"t") {
    value(in: %"Γ", for: %"x", is: %"t")
  },

  // Abs
  .rule("type(knowing:of:is:)", %"Γ", λ(%"x", %"a"), .fact("->", %"t1", %"t2")) {
    .fact("type(knowing:of:is:)", List.cons(pair(%"x", %"t1"), %"Γ"), %"a", %"t2")
  },

  // App
  .rule("type(knowing:of:is:)", %"Γ", app(%"a1", %"a2"), %"t2") {
    .fact("type(knowing:of:is:)", %"Γ", %"a1", .fact("->", %"t1", %"t2")) &&
    .fact("type(knowing:of:is:)", %"Γ", %"a2", %"t1")
  },

])

// Usage example

// We start by creating a mapping that maps the term `x` to `int`.
let Γ = List.from(elements: [pair("x", "int")])

// We create the λ-expression `(λz.λy.z) x`.
let expr = app(λ("z", λ("y", "z")), "x")

// We query the type of the λ-expression.
var answers = kb.ask(type(knowing: Γ, of: expr, is: %"t"))
print(answers.next() ?? "no")
