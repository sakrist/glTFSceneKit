import XCTest
@testable import gltf_scenekit

class gltf_scenekitTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(gltf_scenekit().text, "Hello, World!")
    }


    static var allTests = [
        ("testExample", testExample),
    ]
}
