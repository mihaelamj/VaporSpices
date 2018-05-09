import XCTest
@testable import VaporSpices

final class VaporSpicesTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(VaporSpices().text, "Hello, World!")
    }


    static var allTests = [
        ("testExample", testExample),
    ]
}
