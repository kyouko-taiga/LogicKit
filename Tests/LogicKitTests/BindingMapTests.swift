@testable import LogicKit
import XCTest

class BindingMapTests: XCTestCase {

    func testShallowWalk() {
        let bindingMap: BindingMap = [
            "w": .fact("a"),
            "x": .var("y"),
            "y": .var("z"),
            "z": .fact("t", .var("w"))
        ]

        XCTAssertEqual(bindingMap.shallowWalk(.fact("u")), .fact("u"))
        XCTAssertEqual(bindingMap.shallowWalk(.var("z")) , .fact("t", .var("w")))
        XCTAssertEqual(bindingMap.shallowWalk(.var("y")) , .fact("t", .var("w")))
        XCTAssertEqual(bindingMap.shallowWalk(.var("x")) , .fact("t", .var("w")))
    }

    func testDeepWalk() {
        let bindingMap: BindingMap = [
            "w": .fact("a"),
            "x": .var("y"),
            "y": .var("z"),
            "z": .fact("t", .var("w"))
        ]

        XCTAssertEqual(bindingMap.deepWalk(.fact("u")), .fact("u"))
        XCTAssertEqual(bindingMap.deepWalk(.var("z")) , .fact("t", .fact("a")))
        XCTAssertEqual(bindingMap.deepWalk(.var("y")) , .fact("t", .fact("a")))
        XCTAssertEqual(bindingMap.deepWalk(.var("x")) , .fact("t", .fact("a")))
    }

    func testReified() {
        let bindingMap: BindingMap = [
            "w": .fact("a"),
            "x": .var("y"),
            "y": .var("z"),
            "z": .fact("t", .var("w"))
        ]
        let reifiedMap = bindingMap.reified()

        XCTAssertEqual(reifiedMap["w"], .fact("a"))
        XCTAssertEqual(reifiedMap["x"], .fact("t", .fact("a")))
        XCTAssertEqual(reifiedMap["y"], .fact("t", .fact("a")))
        XCTAssertEqual(reifiedMap["z"], .fact("t", .fact("a")))
    }

    func testBinding() {
        let bindingMap: BindingMap = ["x": .var("y")]
        XCTAssertEqual(bindingMap.binding("v", to: .fact("b"))["v"], .fact("b"))
        XCTAssertEqual(bindingMap.binding("x", to: .fact("b"))["x"], .fact("b"))
    }

    func testMerged() {
        let bindingMap: BindingMap = ["x": .var("y")]
        XCTAssertEqual(bindingMap.merged(with: ["y": .var("z")])["y"], .var("z"))
        XCTAssertEqual(bindingMap.merged(with: ["x": .var("z")])["x"], .var("z"))
    }

}
