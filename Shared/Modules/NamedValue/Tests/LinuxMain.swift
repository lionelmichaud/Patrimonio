import XCTest

import NamedValueTests

var tests = [XCTestCaseEntry]()
tests += NamedValueTests.allTests()
XCTMain(tests)
