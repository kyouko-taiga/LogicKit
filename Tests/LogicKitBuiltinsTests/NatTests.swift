import LogicKit
@testable import LogicKitBuiltins
import XCTest

class NatTests: XCTestCase {

  func testGreater() {
    let kb = KnowledgeBase(knowledge: Nat.relationAxioms)
    var query: Term

    query = Nat.greater(Nat.from(2), Nat.from(2))  // 2 > 2
    XCTAssert(Array(kb.ask(query)).isEmpty)
    query = Nat.greater(Nat.from(5), Nat.from(2))  // 5 > 2
    XCTAssertEqual(Array(kb.ask(query)).count, 1)
    query = Nat.greater(Nat.from(2), Nat.from(5))  // 2 > 5
    XCTAssert(Array(kb.ask(query)).isEmpty)
  }

  func testGreaterOrEqual() {
    let kb = KnowledgeBase(knowledge: Nat.relationAxioms)
    var query: Term

    query = Nat.greaterOrEqual(Nat.from(2), Nat.from(2))  // 2 >= 2
    XCTAssertEqual(Array(kb.ask(query)).count, 1)
    query = Nat.greaterOrEqual(Nat.from(5), Nat.from(2))  // 5 >= 2
    XCTAssertEqual(Array(kb.ask(query)).count, 1)
    query = Nat.greaterOrEqual(Nat.from(2), Nat.from(5))  // 2 >= 5
    XCTAssert(Array(kb.ask(query)).isEmpty)
  }

  func testSmaller() {
    let kb = KnowledgeBase(knowledge: Nat.relationAxioms)
    var query: Term

    query = Nat.smaller(Nat.from(2), Nat.from(2))  // 2 < 2
    XCTAssert(Array(kb.ask(query)).isEmpty)
    query = Nat.smaller(Nat.from(5), Nat.from(2))  // 5 < 2
    XCTAssert(Array(kb.ask(query)).isEmpty)
    query = Nat.smaller(Nat.from(2), Nat.from(5))  // 2 < 5
    XCTAssertEqual(Array(kb.ask(query)).count, 1)
  }

  func testSmallerOrEqual() {
    let kb = KnowledgeBase(knowledge: Nat.relationAxioms)
    var query: Term

    query = Nat.smallerOrEqual(Nat.from(2), Nat.from(2))  // 2 <= 2
    XCTAssertEqual(Array(kb.ask(query)).count, 1)
    query = Nat.smallerOrEqual(Nat.from(5), Nat.from(2))  // 5 <= 2
    XCTAssert(Array(kb.ask(query)).isEmpty)
    query = Nat.smallerOrEqual(Nat.from(2), Nat.from(5))  // 2 <= 5
    XCTAssertEqual(Array(kb.ask(query)).count, 1)
  }

  func testAdd() {
    let kb = KnowledgeBase(knowledge: Nat.arithmeticAxioms)
    let res = Term.var("?")

    var query: Term
    var binding: BindingMap?

    query = Nat.add(Nat.from(2), Nat.from(5), res)  // 2 + 5 = ?
    binding = kb.ask(query).next()
    XCTAssertNotNil(binding)
    XCTAssertEqual(binding!["?"], Nat.from(7))

    query = Nat.add(Nat.from(2), res, Nat.from(7))  // 2 + ? = 7
    binding = kb.ask(query).next()
    XCTAssertNotNil(binding)
    XCTAssertEqual(binding?["?"], Nat.from(5))

    query = Nat.add(res, Nat.from(5), Nat.from(7))  // ? + 5 = 7
    binding = kb.ask(query).next()
    XCTAssertNotNil(binding)
    XCTAssertEqual(binding?["?"], Nat.from(2))
  }

  func testSub() {
    let kb = KnowledgeBase(knowledge: Nat.arithmeticAxioms)
    let res = Term.var("?")

    var query: Term
    var binding: BindingMap?

    query = Nat.sub(Nat.from(2), Nat.from(5), res)  // 2 - 5 = ?
    binding = kb.ask(query).next()
    XCTAssertNil(binding)

    query = Nat.sub(Nat.from(5), Nat.from(2), res)  // 5 - 2 = ?
    binding = kb.ask(query).next()
    XCTAssertNotNil(binding)
    XCTAssertEqual(binding?["?"], Nat.from(3))

    query = Nat.sub(Nat.from(5), res, Nat.from(3))  // 5 - ? = 3
    binding = kb.ask(query).next()
    XCTAssertNotNil(binding)
    XCTAssertEqual(binding?["?"], Nat.from(2))

    query = Nat.sub(res, Nat.from(2), Nat.from(3))  // ? - 2 = 3
    binding = kb.ask(query).next()
    XCTAssertNotNil(binding)
    XCTAssertEqual(binding?["?"], Nat.from(5))
  }

  func testMul() {
    let kb = KnowledgeBase(knowledge: Nat.arithmeticAxioms)
    let res = Term.var("?")

    var query: Term
    var binding: BindingMap?

    query = Nat.mul(Nat.from(5), Nat.from(2), res)  // 5 * 2 = ?
    binding = kb.ask(query).next()
    XCTAssertNotNil(binding)
    XCTAssertEqual(binding?["?"], Nat.from(10))

    query = Nat.mul(Nat.from(5), res, Nat.from(10))  // 5 * ? = 10
    binding = kb.ask(query).next()
    XCTAssertNotNil(binding)
    XCTAssertEqual(binding?["?"], Nat.from(2))

    query = Nat.mul(res, Nat.from(2), Nat.from(10))  // ? * 2 = 10
    binding = kb.ask(query).next()
    XCTAssertNotNil(binding)
    XCTAssertEqual(binding?["?"], Nat.from(5))
  }

  func testDiv() {
    let kb = KnowledgeBase(knowledge: Nat.arithmeticAxioms)
    let res = Term.var("?")

    var query: Term
    var binding: BindingMap?

    query = Nat.div(Nat.from(2), Nat.from(0), res)  // 2 / 0 = ?
    binding = kb.ask(query).next()
    XCTAssertNil(binding)

    query = Nat.div(Nat.from(2), Nat.from(6), res)  // 2 / 6 = ?
    binding = kb.ask(query).next()
    XCTAssertNotNil(binding)
    XCTAssertEqual(binding?["?"], Nat.zero)

    query = Nat.div(Nat.from(6), Nat.from(2), res)  // 6 / 2 = ?
    binding = kb.ask(query).next()
    XCTAssertNotNil(binding)
    XCTAssertEqual(binding?["?"], Nat.from(3))

    query = Nat.div(Nat.from(6), res, Nat.from(3))  // 6 / ? = 3
    binding = kb.ask(query).next()
    XCTAssertNotNil(binding)
    XCTAssertEqual(binding?["?"], Nat.from(2))

     query = Nat.div(res, Nat.from(2), Nat.from(3))  // ? / 2 = 3
     binding = kb.ask(query).next()
     XCTAssertNotNil(binding)
     XCTAssertEqual(binding?["?"], Nat.from(6))

     query = Nat.div(res, Nat.from(3), Nat.from(2))  // ? / 3 = 2
     binding = kb.ask(query).next()
     XCTAssertNotNil(binding)
     XCTAssertEqual(binding?["?"], Nat.from(6))
  }

  func testMod() {
    let kb = KnowledgeBase(knowledge: Nat.arithmeticAxioms)
    let res = Term.var("?")

    var query: Term
    var binding: BindingMap?

    query = Nat.mod(Nat.from(2), Nat.from(0), res)  // 2 % 0 = ?
    binding = kb.ask(query).next()
    XCTAssertNil(binding)

    query = Nat.mod(Nat.from(2), Nat.from(6), res)  // 2 % 6 = ?
    binding = kb.ask(query).next()
    XCTAssertNotNil(binding)
    XCTAssertEqual(binding?["?"], Nat.from(2))

    query = Nat.mod(Nat.from(6), Nat.from(2), res)  // 6 % 2 = ?
    binding = kb.ask(query).next()
    XCTAssertNotNil(binding)
    XCTAssertEqual(binding?["?"], Nat.zero)

    query = Nat.mod(Nat.from(6), Nat.from(4), res)  // 6 % 4 = ?
    binding = kb.ask(query).next()
    XCTAssertNotNil(binding)
    XCTAssertEqual(binding?["?"], Nat.from(2))
  }

  func testAsSwiftInt() {
    XCTAssertEqual(Nat.asSwiftInt(Nat.from(5)), 5)
    XCTAssertNil(Nat.asSwiftInt(Nat.succ(.var("?"))))
  }

}
