@testable import LogicKitTests
@testable import LogicKitParserTests
import XCTest

XCTMain([
     testCase(BindingMapTests.allTests),
     testCase(LogicKitTests.allTests),
     testCase(LogicKitParserTests.allTests),
])
