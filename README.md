# LogicKit

[![Build Status](https://travis-ci.org/kyouko-taiga/LogicKit.svg?branch=master)](https://travis-ci.org/kyouko-taiga/LogicKit)

LogicKit is a Prolog-like language,
distributed in the form of a Swift Embedded Domain Specific Language (EDSL).

## Motivation

[Prolog](https://en.wikipedia.org/wiki/Prolog) is a general purpose logic programming language.
A program is expressed in terms of relations,
and computation in terms of queries over these relations.
The beauty of logic programming is that
we no longer have to tell a computer *how* to compute a result,
but only describe the constraints it should respect.
For instance, the following Prolog snippet finds all the pairs of operands whose sum is 2.

```prolog
add(zero, Y, Y).
add(succ(X), Y, Z) :-
  add(X, succ(Y), Z).

?- add(X, Y, succ(succ(zero))).
```

Writing programs this way is arguably quite interesting.
However, just as any other paradigm, logic programming isn't a fit-them-all solution.
For instance, algorithms that are easily expressed in an imperative way
often prove to be difficult to write in a functional logic programming style.
This is why most modern programming languages, like Swift, are all about miying paradigms.

So why not bringing logic programming into the mix as well!
With LogicKit, the above Prolog example can be rewritten entirely in Swift:

```swift
let zero: Term = "zero"
let x: Term = .var("x")
let y: Term = .var("y")
let z: Term = .var("z")

let kb: KnowledgeBase = [
   .fact("add", zero, y, y),
   .fact("add", .fact("succ", x), y, z) |-
     .fact("add", x, .fact("succ", y), z),
]

var answers = kb.ask(.fact("add", x, y, .fact("succ", .fact("succ", zero))))
for result in answers.prefix(3) {
  print(result)
}
```

## Getting Started

The following is a quick *Getting Started* introduction the installation and use of LogicKit
that only brushes over the library.
You may refer want to refer to the *User Manual* for more details.

### Quick tutorial

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

Being able to query our knowledge base this way is nice,
but only gets us so far.
What's more interesting is to use LogicKit to make deductions.
Let's add a rule to our knowledge base:

```swift
.rule("is stronger", .var("x"), .var("y")) {
  .fact("has type", .var("x"), .var("tx")) &&
  .fact("has type", .var("y"), .var("ty")) &&
  .fact("is effective against", .var("tx"), .var("ty"))
}
```

This rule states that a Pokemon `x` is stronger than a Pokemon `y`
if the type of `x` is effective against that of `y`.
Now we can ask things like:

```swift
var answers = kb.ask(.fact("is stronger", .fact("Charmander"), .fact("Bulbasaur")))
```

or even more interestingly:

```swift
var answers = kb.ask(.fact("is stronger", .var("a"), .var("b")))
```

Note that because the query involves variables,
not only are we interested to know if it is satisfiable,
but also for what binding of `a` and `b`.
Well, in fact each element of the sequence returned by `Knowledge.ask(_:logger:)`
denotes such binding:

```swift
for binding in answers {
  let a = binding["a"]!
  let b = binding["b"]!
  print("\(a) is stronger than \(b)")
}
// Prints "Bulbasaur is stronger than Squirtle"
// Prints "Squirtle is stronger than Charmander"
// Prints "Charmander is stronger than Bulbasaur"
```

Note that since LogicKit is an EDSL,
nothing prevents us from using the full power of Swift to make our definitions more readable:

```swift
let bulbasaur: Term = "Bulbasaur"
let squirtle: Term = "Squirtle"
let charmander: Term = "Charmander"

infix operator !>
func !>(lhs: Term, rhs: Term) -> Term {
  return .fact("is stronger", lhs, rhs)
}

let kb: KnowledgeBase = [
  bulbasaur  !> squirtle,
  squirtle   !> charmander,
  charmander !> bulbasaur,
]

var answers = kb.ask(bulbasaur !> squirtle)
```

LogicKit offers a bunch of syntax sugars to improve the legibility of your code.
Make sure to check the *User Manual* for a comprehensive documentation.

### Builtins types

Here a list of the builtins types you can use directly in LogicKit:

|Builtins types|Constructor|Operators|Helpers|
|---|-----------|---------|---------|
|**Nat**|`zero succ(_:)`|`add(_:_:_:) sub(_:_:_:) mul(_:_:_:)` <br/> ` div(_:_:_:) mod(_:_:_:)` <br/> `  greater(_:_:)  greaterOrEqual(_:_:)` <br/> `smaller(_:_:) smallerOrEqual(_:_:) `| `Nat.from(_:)`<br/>` asSwiftInt(_:)`<br/>`isNat(_:)`|
|**List**|`empty cons(_:_:)`|`count(list:count:)` <br/> `contains(list:element:)`<br/> `concat(_:_:_:)`|`List.from<Collection>(elements:)` <br/> `isList(_:)`|

Example on how to use `List.from`:

```swift
let list = List.from(elements: [1,2,3].map(Nat.from))
// Or
let list = List.from(elements: [Nat.from(1), Nat.from(2), Nat.from(3)])
```

### Installation

LogicKit is distributed in the form of a Swift package
and can be integrated with the [Swift Package Manager](https://swift.org/package-manager/).

Start by creating a new package (unless you already have one):

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

> The master branch of the LogicKit always refers to the latest stable version of LogicKit, so
> using `.branch("master")` to specify the dependency location guarantees you'll always pull the
> latest version. See Swift Package Manager's documentation for alternative configurations.

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

> For Xcode users:
> You can use the Swift Package Manager to create an Xcode project.
> Once you've added LogicKit has a dependency and compiled your project at least once,
> type the command:
>
> ```bash
> swift package generate-xcodeproj
> ```
>
> It will create a `MyLogicProgram.xcodeproj` directory you can edit with Xcode.
> The schemes of the auto-generated package might require some manual configuration.
> Please refer to Xcode's documentation for more information on that end.

## License

LogicKit is licensed under the MIT License.
