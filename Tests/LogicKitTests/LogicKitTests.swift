@testable import LogicKit
import XCTest

class LogicKitTests: XCTestCase {

  func testConstantFacts() {
    let kb: KnowledgeBase = [
      .fact("<", .lit(0), .lit(1)),
      .fact("<", .lit(1), .lit(2)),
      .fact("<", .lit(2), .lit(3)),
    ]

    let answers0 = Array(kb.ask(.fact("<", .lit(0), .lit(1))))
    XCTAssertEqual(answers0.count, 1)
    XCTAssertEqual(answers0[0]   , [:])

    let answers1 = Array(kb.ask(.fact("<", .lit(2), .lit(3))))
    XCTAssertEqual(answers1.count, 1)
    XCTAssertEqual(answers1[0]   , [:])

    let answers2 = Array(kb.ask(.fact("<", .lit(0), .lit(3))))
    XCTAssertEqual(answers2.count, 0)
  }

  func testExtractValue() {
    let swiftValue = [1, 2, 3]
    let atom: Term = .lit(swiftValue)
    XCTAssertEqual(atom.extractValue(ofType: [Int].self), swiftValue)
    XCTAssertNil(atom.extractValue(ofType: Int.self))

    let fact: Term = .fact("hello")
    XCTAssertNil(fact.extractValue(ofType: String.self))
  }

  func testFactsWithVariables() {
    let kb: KnowledgeBase = [
      .fact("<", .lit(0), .lit(1)),
      .fact("<", .lit(1), .lit(2)),
      .fact("<", .lit(2), .lit(3)),
    ]

    let answers0 = Array(kb.ask(.fact("<", .lit(0), .var("x"))))
    XCTAssertEqual(answers0.count, 1)
    XCTAssertEqual(answers0[0]   , ["x": .lit(1)])

    let answers1 = Array(kb.ask(.fact("<", .var("x"), .var("y"))))
    XCTAssertEqual(answers1.count, 3)
    XCTAssert(answers1.contains(where: { $0["x"] == .lit(0) && $0["y"] == .lit(1) }))
    XCTAssert(answers1.contains(where: { $0["x"] == .lit(1) && $0["y"] == .lit(2) }))
    XCTAssert(answers1.contains(where: { $0["x"] == .lit(2) && $0["y"] == .lit(3) }))
  }

  func testSimpleDeductions() {
    let kb: KnowledgeBase = [
      .fact("play" , "mia"),
      .rule("happy", "mia") {
        .fact("play", "mia")
      },
    ]

    let answers0 = Array(kb.ask(.fact("happy", "mia")))
    XCTAssertEqual(answers0.count, 1)
    XCTAssertEqual(answers0[0]   , [:])

    let answers1 = Array(kb.ask(.fact("happy", .var("who"))))
    XCTAssertEqual(answers1.count, 1)
    XCTAssertEqual(answers1[0]   , ["who": "mia"])
  }

  func testDisjunction() {
    let x: Term = .var("x")
    let kb: KnowledgeBase = [
      .fact("hot", "fire"),
      .fact("cold", "ice"),
      .rule("painful", x) {
        .fact("hot", x) || .fact("cold", x)
      },
    ]

    let answers = Array(kb.ask(.fact("painful", x)))
    XCTAssertEqual(answers.count, 2)

    let results = Set(answers.compactMap({ $0["x"] }))
    XCTAssert(results.contains("fire"))
    XCTAssert(results.contains("ice"))
  }

  func testRecursion() {
    let x   : Term = .var("x")
    let y   : Term = .var("y")
    let z   : Term = .var("z")
    let zero: Term = "zero"

    func succ(_ x: Term) -> Term {
      return .fact("succ", x)
    }

    func nat(value n: Int) -> Term {
      if n == 0 {
        return zero
      } else {
        return succ(nat(value: n - 1))
      }
    }

    let kb: KnowledgeBase = [
      .fact("diff", zero, x, x),
      .fact("diff", x, zero, x),
      .rule("diff", succ(x), succ(y), z) {
        .fact("diff", x, y, z)
      },
    ]

    let query: Term = .fact("diff", nat(value: 2), nat(value: 4), .var("result"))
    let answers = kb.ask(query)
    let answer  = answers.next()
    XCTAssertNotNil(answer)
    XCTAssertEqual(answer?["result"], nat(value: 2))
  }

  func testBacktracking() {
    let x: Term = .var("x")
    let y: Term = .var("y")
    let z: Term = .var("z")
    let w: Term = .var("w")

    let kb: KnowledgeBase = [
      .fact("link", "0", "1"),
      .fact("link", "1", "2"),
      .fact("link", "2", "4"),
      .fact("link", "1", "3"),
      .fact("link", "3", "4"),
      .rule("path", x, y, .fact("c", x, .fact("c", y, "nil"))) {
        .fact("link", x, y)
      },
      .rule("path", x, y, .fact("c", x, w)) {
        .fact("link", x, z) && .fact("path", z, y, w)
      }
    ]

    let query: Term = .fact("path", "0", "4", .var("nodes"))
    let answers = Array(kb.ask(query))

    // There should be two paths from 0 to 4.
    XCTAssertEqual(answers.count, 2)

    // All paths should bind the variable `nodes`.
    XCTAssertNotNil(answers[0]["nodes"])
    XCTAssertNotNil(answers[1]["nodes"])
  }

  func testNative() {
    let isTextOutputStream = "isTextOutputStream"/1
    let a: Term = .var("a")

    let kb: KnowledgeBase = [
      isTextOutputStream(a) |- .native { t in
        t["a"]?.extractValue() is TextOutputStream
      }
    ]

    let query: Term = isTextOutputStream("Koala")
    let answer = kb.ask(query).next()
    XCTAssertNotNil(answer)
  }

  func testLitSyntax() {
    let play  : Term = "play"
    let mia   : Term = "mia"
    let happy : Term = "happy"
    let who   = Term.var("who")
    let kb: KnowledgeBase = [
      play[mia],
      (play[mia] && play[mia]) => happy[mia],
    ]

    let answers0 = Array(kb.ask(happy[mia]))
    XCTAssertEqual(answers0.count, 1)
    XCTAssertEqual(answers0[0]   , [:])

    let answers1 = Array(kb.ask(happy[who]))
    XCTAssertEqual(answers1.count, 1)
    XCTAssertEqual(answers1[0]       , ["who": mia])
    XCTAssertEqual(answers1[0]["who"], mia)
    XCTAssertEqual(answers1[0][who]  , mia)

    XCTAssertEqual(
      (play[mia] && play[mia]) => happy[mia],
      happy[mia] |- (play[mia] && play[mia])
    )
    XCTAssertEqual(
      (play[mia] && play[mia]) => happy[mia],
      happy[mia] |- (play[mia] && play[mia])
    )
    XCTAssertEqual(
      (play[mia] && play[mia]) => happy[mia],
      happy[mia] ⊢ (play[mia] ∧ play[mia])
    )
    XCTAssertEqual(
      (play[mia] && play[mia]) => happy[mia],
      happy[mia] ⊢ (play[mia] ∧ play[mia])
    )
  }

}
