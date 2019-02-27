# LogicKit's User Manual

This user manual documents the installation and usage of the LogicKit library.

## Installation

### Swift Package Manager

The recommended approach to integrate LogicKit with your project is to declare it as a dependency
by the means of the [Swift Package Manager](https://swift.org/package-manager/).

The most likely use case is to use LogicKit in an executable package.
Start by creating a new package:

```bash
mkdir MyLogicProgram
cd MyLogicProgram
swift package init --type executable
```

Then add LogicKit as a dependency to your package, from your `Package.swift` file:

```swift
import PackageDescription

let package = Package(
  name: "MyLogicProgram",
  dependencies: [
    .package(url: "https://github.com/kyouko-taiga/LogicKit", .branch("master")),
  ],
  targets: [
    .target(name: "MyLogicProgram", dependencies: ["LogicKit"]),
  ]
)
```

LogicKit adopts [semantic versioning](https://semver.org) to label its releases,
which is fully compatible with the way Swift Package Manager handles dependency versions.
Hence, you may replace `.branch("master")` with any other particular specification
to have a better control over the version your code is linked against.
Please refer to Swift Package Manager's documentation for the syntax of such specifications.
The master branch of the LogicKit repository always refers to the latest stable version of LogicKit,
so linking against `.branch("master")` guarantees your project will always pull the latest version.

Make sure the Swift Package Manager is able to properly download, compile and link LogicKit
with the following command:

```bash
swift build
```

If everything goes well,
you should then be able to import LogicKit in your own Swift sources:

```swift
import LogicKit

// Your code here ...
```

To update your package with the latest version of LogicKit,
simply run the following command:

```bash
swift package update
```

### Xcode

Xcode users may also use Swift Package Manager to create their Xcode projects.
Once you've added LogicKit has a dependency and compiled your project at least once,
type the command:

```bash
  swift package generate-xcodeproj
```

It will create a `MyLogicProgram.xcodeproj` directory you can edit with Xcode.
The schemes of the auto-generated package might require some manual configuration.
Please refer to Xcode's documentation for more information on that end.

To integrate LogicKit with an existing Xcode project **without** using Swift Package Manager,
create two targets in your project: `LogicKit` and `LogicKitBuiltins`.
Copy the files in `Sources/LogicKit/` and `Sources/LogicKitBuiltins` to your own project,
and add them to the build phase of your `LogicKit` and `LogicKitBuiltins` targets, respectively.

## Usage

### Simple Facts

Like Prolog, LogicKit revolves around a knowledge base (or database),
against which one can make queries.
There are four constructs in LogicKit:
Facts (`Term.fact(_:_:)`) that denote predicates and propositions,
rules (`Term.rule(_:_:_:)`) that denote conditional facts,
literals (`Term.lit(_:)`) that denote atomic values, and
variables (`Term.var(_:)`) that act as placeholders for other terms.

Knowledge bases are nothing more than a collection of such constructs:

```swift
let kb: KnowledgeBase = [
  .fact("is effective against", .fact("water"), .fact("fire")),
  .fact("is effective against", .fact("fire"), .fact("grass")),
  .fact("is effective against", .fact("grass"), .fact("water")),

  .fact("has type", .fact("Bulbasaur"), .fact("grass")),
  .fact("has type", .fact("Squirtle"), .fact("water")),
  .fact("has type", .fact("Charmander"), .fact("fire")),
]
```

The above knowledge base only makes use of facts and propositions.
It states for instance that *water is effective against fire*,
or that *Squirtle has type water*.
One can query such knowledge base as follows:

```swift
var answers = kb.ask(.fact("has type", .fact("Squirtle"), .fact("water")))
```

Since there might be several answers to a single query,
`Knowledge.ask(_:logger:)` doesn't return a single yes/no answer.
Instead, it returns a sequence whose each element denote one correct answer.
If the sequence is empty, then there isn't any solution.

```swift
print("Squirtle has type water:", answers.next() != nil)
// Prints "Squirtle has type water: true"
```

The type `Term` conforms to Swift's [`ExpressibleByStringLiteral`](https://developer.apple.com/documentation/swift/expressiblebystringliteral) protocol,
so that propositions (i.e. terms of arity 0) may be written as simple string literals.
Therefore, one can rewrite the above knowledge base as follows:

```swift
let kb: KnowledgeBase = [
  .fact("is effective against", "water", "fire"),
  .fact("is effective against", "fire", "grass"),
  .fact("is effective against", "grass", "water"),

  .fact("has type", "Bulbasaur", "grass"),
  .fact("has type", "Squirtle", "water"),
  .fact("has type", "Charmander", "fire"),
]
```

See the *API* section for more details and examples about LogicKit's syntax sugars.

### Variables and Unification

Being able to query our knowledge base this way has its use cases,
but does not improve much from using a simple set.
What's more interesting is to query a knowledge base for information we do not fully have.
For instance, one could wonder what Pokemon has type grass.
This is done by the means of *variables*.

```swift
var answers = kb.ask(.fact("has type", .var("x"), "grass"))
```

The above query reads as *Pokemon `x` has type grass*,
`X` being a variable that could represent any term.

Unlike before, when we were simply asking whether or not something is known for fact,
we now also want to know for *which* values a given term is a fact.
Fortunately, `Knowledge.ask(_:logger:)` gives us everything we need to answer that question.
The method returns an instance of type called `AnswerSet`,
which acts as a sequence of bindings that map variable names to terms.
Therefore one should iterate over it to pull all possible results:

```swift
for answer in answers {
  print(answer["x"]!, "has type grass")
}
```

> There's only a single result in our particular example,
> but try to modify the knowledge base so that the above query may have multiple valid answers.

Queries are not constrained to contain a single variable.
Hence, one could for instance ask for all pairs of Pokemon/type with the following query:

```swift
var answers = kb.ask(.fact("has type", .var("x"), .var("y")))
for answer in answers {
  print(answer["x"]!, "has type", answer["y"]!)
}
```

LogicKit relies on [*unification*](https://en.wikipedia.org/wiki/Unification_(computer_science))
to carry out its deductions.
In a nutshell, given two term `p($x, b)` and `p(a, $y)`,
the engine attempts to find values for each free variable so that both terms are equal
(i.e. `$x := a` and `$y := b` in this particular example).
Unification usually occurs implicitly,
when a given term is matched with a particular *pattern*.
Nevertheless, a special built-in predicate `~=~` allows one to request unification explicitly:

```swift
let goal: Term = .fact("a") ~=~ .var("x")
```

### Rules

Being able to query our knowledge base this way is nice,
but only gets us so far.
What's more interesting is to use LogicKit to make more elaborate deductions.
Let's add a rule to our knowledge base:

```swift
let kb: KnowledgeBase = [

  // Keep the facts previously defined here ...

  .rule("is stronger", .var("x"), .var("y")) {
    .fact("has type", .var("x"), .var("tx")) &&
    .fact("has type", .var("y"), .var("ty")) &&
    .fact("is effective against", .var("tx"), .var("ty"))
  },
]
```

This rule states that a Pokemon `x` is stronger than a Pokemon `y`
if the type of `x` is effective against that of `y`.
Now we can ask things like:

```swift
var answers = kb.ask(.fact("is stronger", "Charmander", "Bulbasaur"))
print(answers.next() != nil)
```

or even more interestingly:

```swift
var answers = kb.ask(.fact("is stronger", .var("a"), .var("b")))
for answer in answers {
  print(answer["a"]!, "has type", answer["b"]!)
}
```

### Atomic Values (a.k.a. Literals)

The 4th construct of LogicKit is the atomic value (a.k.a. literal).
An atomic value is like a proposition,
but can be represented by any type of Swift, as long as it is `Hashable`.
For instance, one may create the following program:

```swift
let kb: KnowledgeBase = [
  .fact("is big", .lit(1 ... 10_000_000)),
  .fact("is small", .lit(1 ... 2)),
]

var answers = kb.ask(.fact("is big", .var("a")))
for answer in answers {
  print(answer["a"]!, "is big")
}
```

Note however than LogicKit doesn't interact the same way with atomic values as it does with regular terms.
Indeed, LogicKit sees them as equatable black boxes,
but can't use any predicate on their intrinsic value to make deductions.
They are indeed *atomic*.
For instance, one may store a whole Swift array as an atomic value,
but may not ask LogicKit to use its values to make deductions.

> Swift's `String` is obviously hashable, and hence could be used as a literal value. This is
> however discouraged, as using character strings as propositions offers more flexibility.

Why using atomic values at all then?
Because they can act as a glue between native Swift code and logic programs written with LogicKit.
While one cannot use predicates on their intrinsic value,
one may write a knowledge base that defines predicates over their identity.

### Troubleshooting

Debugging a logic program can be a little daunting,
as one cannot easily follow the sequence of instructions the machine will do,
which is quite a departure from the much more classic imperative paradigm.
Nevertheless, LogicKit offers a rudimental way to get a look into its deduction engine,
by the means of a logger.

The method `Knowledge.ask(_:logger:)` accepts an optional logger
(i.e. any type that conforms to LogicKit's `Logger` protocol).
If provided, LogicKit will call the methods
`Logger.willRealize(goal:)`,
`Logger.willAttempt(clause:)` and
`Logger.didBacktrack()`
so as to provide the user with some information about the current state of its engine.

A default logger named `DefaultLogger`
that simply prints every call to the above methods
is shipped with LogicKit.

```swift
var answers = kb.ask(.fact("is stronger", .var("a"), .var("b")), logger: DefaultLogger())
_ = Array(answers)

// Prints:
//
//     Attempting to realize has type[$x, $tx]
//     using has type[Bulbasaur, grass]
//     Attempting to realize has type[$y, $ty]
//     using has type[Bulbasaur, grass]
//     Attempting to realize is effective against[grass, grass]
//     using is effective against[water, fire]
//     using is effective against[fire, grass]
//     using is effective against[grass, water]
//     using has type[Squirtle, water]
//     Attempting to realize is effective against[grass, water]
//     using is effective against[water, fire]
//     using is effective against[fire, grass]
//     using is effective against[grass, water]
//     Attempting to realize is effective against[grass, water]
//     backtacking
//     ...
//
```

## API

This section describes the API of LogicKit,
with a particular focus on its syntax sugars.

### The `Term` Enumeration

At the core of the API sits the `Term` enumeration,
that describes the data type handled by LogicKit.
Although the enumeration has 5 cases,
namely `var`, `val`, `_term`, `_rule`, `conjunction` and `disjunction`,
only the first one should be manipulated directly by the user code.
More elaborated constructors are available for other cases.

**Atomic Values**:

The static method `Term.lit<T>(_:)` creates atomic values.
It accepts any value as argument, as long as its type conforms to `Hashable`,
and wraps it within a term.

```swift
let atom: Term = .lit([1, 2, 3])
```

You may use the method `Term.extractValue(ofType:)` to extract a value from a term.
The method expects the type of the value to extract as parameter.
Note that the function returns an optional,
that will be set to `nil` if the term either isn't an atomic value,
or doesn't wrap a value with the requested type.

```swift
let array = atom.extractValue(ofType: [Int].self)
```

**Facts**:

Facts can be created with the static method `Term.fact(name:arguments:)`,
which expects a functor name and an arbitrary number arguments,
in the form of terms.

```swift
let proposition: Term = .fact("proposition")
print(proposition)
// Prints "proposition"

let predicate1: Term = .fact("is a letter", "a")
print(predicate1)
// Prints "is a letter[a]"

let predicate2: Term = .fact("is shorter", .lit([1, 2]), .lit([2, 3, 4]))
print(predicate2)
// Prints "is shorter[[1, 2], [2, 3, 4]]"
```

Notice that because `Term` conforms to `ExpressibleByStringLiteral`,
the argument of the predicate `is a letter` is indeed a term,
and not an atomic value.

Facts may also be created by subscripting propositions with an arbitrary number of arguments.
In this case, the proposition becomes the functor of the produced term.

```swift
let love: Term = "love"
print(love["Ash", "Pikachu"])
// Prints "love(Ash, Pikachu)"
```

> Attempting to subscript a term that is not a proposition will trigger an unrecoverable error.

**Rules**:

Facts can be created with the static method `Term.rule(name:arguments:body:)`,
which expects a functor name, an arbitrary number arguments in the form of terms,
and a closure that returns the rule's body, also as a term.

```swift
let pred: Term = .rule("painful", .var("x")) {
  .fact("too hot", .var("x")) || .fact("too cold", .var("x"))
}
print(pred)
// Print "(painful[$x] ⊢ (too hot[$x] ∨ too cold[$x]))"
```

Using `Term.rule(name:arguments:body:)` is recommended,
as it's simpler to parse by the Swift compiler, compared to other constructuors.
Therefore the compiler is likely to produce more insightful error messages in case of syntax errors.
Nevertheless, you may use the operators `=>`, `|-` or `⊢` to achieve the same result.

```swift
let pred1: Term = .fact("too hot", .var("x")) || .fact("too cold", .var("x")) =>
  .fact("painful", .var("x"))
let pred2: Term = .fact("painful", .var("x")) |-
  .fact("too hot", .var("x")) || .fact("too cold", .var("x"))
let pred3: Term = .fact("painful", .var("x")) ⊢
  .fact("too hot", .var("x")) || .fact("too cold", .var("x"))
```

**Conjunctions and Disjunction**:

Conjunctions and disjunction of terms can be created with the operators `&&` and `||`,
respectively.
A variant of each operator that more closely resembles formal notations is also available.

```swift
let pred1: Term = .fact("a") && .var("x")
let pred2: Term = .fact("a") ∧ .var("x")

let pred3: Term = .fact("a") || .var("x")
let pred4: Term = .fact("a") ∨ .var("x")
```

**Unification Predicate**

A special built-in predicate allows one to express a goal as the mere unification of two terms.
It can be constructed with the operator `~=~`.

```swift
let pred: Term = love["Ash", "Pikachu"] ~=~ love["Ash", .var("x")]
```

### Built-ins

LogicKit comes with some built-ins facts and rules that are commonly found in knowledge bases.
See `Sources/LogicKitBuiltins` for the exhaustive list.

First, import the Swift module where they are defined:

```swift
import LogicKitBuiltins
```

All built-in modules are in the form of a namespace that contains generators for the related terms,
constructors for their predicates and a static variable `axioms` with the corresponding facts and rules.

```swift
import LogicKitBuiltins

let kb = KnowledgeBase(knowledge: Nat.axioms)
let query = Nat.mul(Nat.from(2), Nat.from(5), .var("x"))  // 5 * 2 = x
let binding = kb.ask(query).next()
print(Nat.asSwiftInt(binding!["x"]!)!)
// Prints "10"
```
