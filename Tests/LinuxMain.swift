import XCTest
@testable import AppTests

XCTMain([ testCase(BookTests.allTests), testCase(CategoryTests.allTests), testCase(UserTests.allTests)
])
