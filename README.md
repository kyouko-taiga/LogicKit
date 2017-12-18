# LogicKit

LogicKit is a Prolog-like language,
distributed in the form of a Swift Embedded Domain Specific Language (EDSL).

## Motivation

[Prolog](https://en.wikipedia.org/wiki/Prolog) is a general purpose logic programming language.
A program is expressed in terms of relations,
and computation in terms of queries over these relations.
The beauty of logic programming is that
we no longer have to tell a computer *how* to compute a result,
but only describe the constrains it should respect.
For instance, the following Prolog snippet finds all the pairs of operands whose sum is 2.

```prolog
add(zero, Y, Y).
add(succ(X), Y, Z) :-
  add(X, succ(Y), Z).

?- add(X, Y, succ(succ(zero))).
```

This is nice and all, but as any other paradigm, logic programming isn't a fit-them-all solution.
Let's imagine we've to program a complex user interface with a lot of stateful components.
In fact, algorithms that are easily expressed in an imperative way
often prove to be difficult to write in a functional logic programming style.

But modern languages like Swift are all about mixing paradigms right?
So why not bringing logic programming into the mix as well!
With LogicKit, the above Prolog example can be rewritten entirely in Swift:

```swift
let zero: Term = .lit("zero")
let x   : Term = .var("x")
let y   : Term = .var("y")
let z   : Term = .var("z")

let kb: KnowledgeBase = [
   .fact("add", zero, y, y),
   .rule("add", .fact("succ", x), y, z) {
     .fact("add", x, .fact("succ", y), z)
   }
]

let answers = kb.ask(.fact("add", x, y, .fact("succ", .fact("succ", zero))))
```

## Getting started

### Quick tutorial

Like Prolog, LogicKit revolves around a knowledge base (or database),
against which one can make queries.
There are four constructs in LogicKit:
literals (`Term.lit(_:)`) that denote atomic values,
facts (`Term.fact(_:_:)`) that denote predicates,
rules (`Term.rule(_:_:_:)`) that denote conditional facts and
variables (`Term.var(_:)`) that act as placeholders for other terms.

Knowledge bases are nothing more than a collection of such constructs:

```swift
let kb: KnowledgeBase = [
  .fact("is effective against", .lit("water"), .lit("fire")),
  .fact("is effective against", .lit("fire") , .lit("grass")),
  .fact("is effective against", .lit("grass"), .lit("water")),

  .fact("has type", .lit("Bulbasaur") , .lit("grass")),
  .fact("has type", .lit("Squirtle")  , .lit("water")),
  .fact("has type", .lit("Charmander"), .lit("fire")),
]
```

The above knowledge base only makes use of facts and literals.
It states for instance that *water is effective against fire*,
or that *Squirtle has type water*.
One can query such knowledge base as follows:

```swift
var answers = kb.ask(.fact("has type", .lit("Squirtle"), .lit("water")))
```

Since there might be several answers to a single query,
`Knowledge.ask(_:_:)` doesn't return a single yes/no answer.
Instead, it returns a sequence whose each element denote one correct answer.
If the sequence is empty, then there isn't any solution.

```swift
print("Squirtle has type water:" answers.next() != nil)
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
let answers = kb.ask(.fact("is stronger", .lit("Charmander"), .lit("Bulbasaur")))
```

or even more interestingly:

```swift
let answers = kb.ask(.fact("is stronger", .var("a"), .var("b")))
```

Note that because the query involves variables,
not only are we interested to know if it is satisfiable,
but also for what binding of `a` and `b`.
Well, in fact each element of the sequence returned by `Knowledge.ask(_:_:)`
denotes such a binding:

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
let bulbasaur : Term = .lit("Bulbasaur")
let squirtle  : Term = .lit("Squirtle")
let charmander: Term = .lit("Charmander")

infix operator !>
func !>(lhs: Term, rhs: Term) -> Term {
  return .fact("is stronger", lhs, rhs)
}

let kb: KnowledgeBase = [
  bulbasaur  !> squirtle,
  squirtle   !> charmander,
  charmander !> bulbasaur,
]

let answer = kb.ask(bulbasaur !> squirtle)
```

### Installation

LogicKit is distributed in the form of a Switch package
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
        .package(url: "https://github.com/kyouko-taiga/LogicKit", from: "1.0.0"),
    ],
    targets: [
        .target(name: "MyLogicProgram", dependencies: ["LogicKit"]),
    ]
)
```

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
> It will create a `YourPackage.xcodeproj` directory you can edit with Xcode.
> The schemes of the auto-generated package might require some manual configuration.
> Please refer to Xcode's documentation for more information on that end.

### Using the interpreter

LogicKit comes with an interpreter, `lki`,
that you can use to design and/or debug knowledge bases.
To use the interpreter, first clone this repository:

```bash
git clone git@github.com:kyouko-taiga/LogicKit.git
```

You can then compile `lki`:

```bash
swift build --configuration release --product lki
```

Which will create a binary `lki` in `.build/release/`.
Feel free to symlink copy or symlink this binary to include it in your path.

To use `lki`, first write your knowledge base in some file, for instance `nat.kb`:

```swift
.fact("add", zero, y, y),
.rule("add", .fact("succ", x), y, z) {
  .fact("add", x, .fact("succ", y), z)
}
```

Then, invoke the interpreter with a path to your knowledge base:

```bash
lki /path/to/nat.kb
```

You'll be presented a prompt that lets you issue queries against your knowledge base.

> Note that `lki` can only read knowledge bases written with the LogicKit syntax,
> meaning that you can't use the full power of Swift
> like you would be able to in actual Swift sources.

## License

LogicKit is licensed under the MIT License.
