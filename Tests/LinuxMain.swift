import XCTest

import LogicKitTests
import LogicKitBuiltinsTests

var tests = [XCTestCaseEntry]()
tests += LogicKitTests.__allTests()
tests += LogicKitBuiltinsTests.__allTests()

XCTMain(tests)
