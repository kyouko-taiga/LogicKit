@testable import LogicKit
import XCTest

class KnowledgeBaseTests: XCTestCase {

  func testMerge() {
    let kb1: KnowledgeBase = [
      .fact("foo", "bar"),
      .rule("foo", .var("x")) {
        .fact("foo", .var("x"))
      },
      .lit(12),
      .lit(13),
    ]

    let kb2: KnowledgeBase = [
      .fact("foo", "bar"),
      .rule("foo", .var("y")) {
        .fact("foo", .var("y"))
      },
      .lit(12),
      .lit(14),
    ]

    let knowledge = Array(kb1 + kb2)
    XCTAssert(knowledge.contains(.fact("foo", "bar")))
    XCTAssert(knowledge.contains(.rule("foo", .var("x")) { .fact("foo", .var("x")) }))
    XCTAssert(knowledge.contains(.rule("foo", .var("y")) { .fact("foo", .var("y")) }))
    XCTAssert(knowledge.contains(.lit(12)))
    XCTAssert(knowledge.contains(.lit(13)))
    XCTAssert(knowledge.contains(.lit(14)))

    XCTAssertEqual(knowledge.filter({ $0 == .fact("foo", "bar") }).count, 1)
    XCTAssertEqual(knowledge.filter({ $0 == .lit(12) }).count, 1)
  }

}
