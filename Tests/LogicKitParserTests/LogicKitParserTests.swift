@testable import LogicKit
@testable import LogicKitParser
import XCTest

#if swift(>=4.0)
#else
class LogicKitParserTests: XCTestCase {

    func testParseVariable() {
        XCTAssertEqual(try Grammar.variable.parse(".var(\"x\")")  , .var("x"))
        XCTAssertEqual(try Grammar.variable.parse(".var( \"x\")") , .var("x"))
        XCTAssertEqual(try Grammar.variable.parse(".var(\"x\" )") , .var("x"))
        XCTAssertEqual(try Grammar.variable.parse(".var( \"x\" )"), .var("x"))
    }

    func testParseLiteral() {
        XCTAssertEqual(try Grammar.literal.parse(".lit(\"a\")")   , .lit("a"))
        XCTAssertEqual(try Grammar.literal.parse(".lit( \"a\")")  , .lit("a"))
        XCTAssertEqual(try Grammar.literal.parse(".lit(\"a\" )")  , .lit("a"))
        XCTAssertEqual(try Grammar.literal.parse(".lit( \"a\" )") , .lit("a"))

        XCTAssertEqual(try Grammar.literal.parse(".lit(0)")       , .lit(0))
        XCTAssertEqual(try Grammar.literal.parse(".lit(true)")    , .lit(true))
    }

    func testParseFact() {
        XCTAssertEqual(try Grammar.fact.parse(".fact(\"a\")")     , .fact("a"))
        XCTAssertEqual(try Grammar.fact.parse(".fact( \"a\")")    , .fact("a"))
        XCTAssertEqual(try Grammar.fact.parse(".fact(\"a\" )")    , .fact("a"))
        XCTAssertEqual(try Grammar.fact.parse(".fact( \"a\" )")   , .fact("a"))

        XCTAssertEqual(
            try Grammar.fact.parse(".fact(\"a\", .var(\"x\"))"),
            .fact("a", .var("x")))
        XCTAssertEqual(
            try Grammar.fact.parse(".fact(\"a\" , .var(\"x\"))"),
            .fact("a", .var("x")))
        XCTAssertEqual(
            try Grammar.fact.parse(".fact(\"a\", .var(\"x\"), .var(\"y\"))"),
            .fact("a", .var("x"), .var("y")))
        XCTAssertEqual(
            try Grammar.fact.parse(".fact(\"a\", .fact(\"a\", .var(\"x\")))"),
            .fact("a", .fact("a", .var("x"))))
    }

    func testParseRule() {
        XCTAssertEqual(try Grammar.rule.parse(
            ".rule(\"a\") { .var(\"x\") }"), .rule("a") { .var("x") })
        XCTAssertEqual(try Grammar.rule.parse(
            ".rule( \"a\"){ .var(\"x\") }"), .rule("a") { .var("x") })
        XCTAssertEqual(try Grammar.rule.parse(
            ".rule(\"a\" ) {.var(\"x\") }"), .rule("a") { .var("x") })
        XCTAssertEqual(try Grammar.rule.parse(
            ".rule( \"a\" ) {.var(\"x\")}"), .rule("a") { .var("x") })

        let input =
        """
        .rule("a") {
            .var("x")
        }
        """
        XCTAssertEqual(try Grammar.rule.parse(input), .rule("a") { .var("x") })
    }

    func testParseConjunction() {
        XCTAssertEqual(try Grammar.conjunction.parse(
            ".var(\"x\") && .var(\"y\")"), .var("x") && .var("y"))
        XCTAssertEqual(try Grammar.conjunction.parse(
            ".var(\"x\") && .var(\"y\") && .var(\"z\")"), .var("x") && .var("y") && .var("z"))
    }

    func testParseDisjunction() {
        XCTAssertEqual(try Grammar.disjunction.parse(
            ".var(\"x\") || .var(\"y\")"), .var("x") || .var("y"))
        XCTAssertEqual(try Grammar.disjunction.parse(
            ".var(\"x\") || .var(\"y\") || .var(\"z\")"), .var("x") || .var("y") || .var("z"))
    }

    func testParsePrecedence() {
        XCTAssertEqual(try Grammar.disjunction.parse(
            ".var(\"x\") || .var(\"y\") && .var(\"z\")"), .var("x") || .var("y") && .var("z"))
    }

}
#endif
