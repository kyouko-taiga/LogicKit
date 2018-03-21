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
            .fact("play" , .lit("mia")),
            .rule("happy", .lit("mia")) {
                .fact("play", .lit("mia"))
            },
        ]

        let answers0 = Array(kb.ask(.fact("happy", .lit("mia"))))
        XCTAssertEqual(answers0.count, 1)
        XCTAssertEqual(answers0[0]   , [:])

        let answers1 = Array(kb.ask(.fact("happy", .var("who"))))
        XCTAssertEqual(answers1.count, 1)
        XCTAssertEqual(answers1[0]   , ["who": .lit("mia")])
    }

    func testRecursion() {
        let x   : Term = .var("x")
        let y   : Term = .var("y")
        let z   : Term = .var("z")
        let zero: Term = .lit("zero")

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
        var answers = kb.ask(query)
        let answer  = answers.next()
        XCTAssertNotNil(answer)
        XCTAssertEqual(answer?["result"], nat(value: 2))
    }

    func testLitSyntax() {
        let play  : Term = "play"
        let mia   : Term = "mia"
        let happy : Term = "happy"
        let kb: KnowledgeBase = [
            play[mia],
            { play[mia] && play[mia] } => happy[mia],
        ]

        let answers0 = Array(kb.ask(happy[mia]))
        XCTAssertEqual(answers0.count, 1)
        XCTAssertEqual(answers0[0]   , [:])

        let answers1 = Array(kb.ask(happy[.var("who")]))
        XCTAssertEqual(answers1.count, 1)
        XCTAssertEqual(answers1[0]   , ["who": mia])

        XCTAssertEqual(
          { play[mia] && play[mia] } => happy[mia],
          (play[mia] && play[mia]) => happy[mia]
        )
        XCTAssertEqual(
          { play[mia] && play[mia] } => happy[mia],
          happy[mia] |- { play[mia] && play[mia] }
        )
        XCTAssertEqual(
          { play[mia] && play[mia] } => happy[mia],
          happy[mia] |- (play[mia] && play[mia])
        )
        XCTAssertEqual(
          { play[mia] && play[mia] } => happy[mia],
          happy[mia] ⊢ { play[mia] ∧ play[mia] }
        )
        XCTAssertEqual(
          { play[mia] && play[mia] } => happy[mia],
          happy[mia] ⊢ (play[mia] ∧ play[mia])
        )
    }

    static var allTests = [
        ("testConstantFacts"     , testConstantFacts),
        ("testFactsWithVariables", testFactsWithVariables),
        ("testSimpleDeductions"  , testSimpleDeductions),
        ("testRecursion"         , testRecursion),
        ("testLitSyntax"         , testLitSyntax),
    ]

}
