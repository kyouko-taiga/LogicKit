import LogicKit
@testable import LogicKitBuiltins
import XCTest

class ListTests: XCTestCase {

  func testCount() {
    let kb = KnowledgeBase(knowledge: List.countAxioms)
    var query: Term
    var binding: BindingMap?

    let list = List.from(elements: ["1", "2", "3"])

    query = List.count(list: list, count: .var("?"))
    binding = kb.ask(query).next()
    XCTAssertNotNil(binding)
    XCTAssertEqual(binding?["?"],  Nat.from(3))
  }

  func testContains() {
    let kb = KnowledgeBase(knowledge: List.containsAxioms)
    var query: Term
    var binding: BindingMap?

    let list = List.from(elements: ["1", "2", "3"])

    query = List.contains(list: list, element: "0")
    binding = kb.ask(query).next()
    XCTAssertNil(binding)

    query = List.contains(list: list, element: "1")
    binding = kb.ask(query).next()
    XCTAssertNotNil(binding)
    query = List.contains(list: list, element: "2")
    binding = kb.ask(query).next()
    XCTAssertNotNil(binding)
    query = List.contains(list: list, element: "3")
    binding = kb.ask(query).next()
    XCTAssertNotNil(binding)
  }

  func testConcat() {
    let kb = KnowledgeBase(knowledge: List.concatAxioms)
    var query: Term
    var binding: BindingMap?

    let list1 = List.from(elements: ["1", "2", "3"])
    let list2 = List.from(elements: ["4", "5", "6"])

    query = List.concat(list1, list2, .var("?"))
    binding = kb.ask(query).next()
    XCTAssertNotNil(binding)
    XCTAssertEqual(binding?["?"],  List.from(elements: ["1", "2", "3", "4", "5", "6"]))
  }

}
