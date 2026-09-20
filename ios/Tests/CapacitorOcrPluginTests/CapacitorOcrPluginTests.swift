import XCTest
import Capacitor
@testable import CapacitorOcrPlugin

class CapacitorOcrPluginTests: XCTestCase {
    func testDetectTextRejectsCallWithoutImage() {
        let plugin = CapacitorOcr()
        let rejected = expectation(description: "call is rejected")

        let call = CAPPluginCall(callbackId: "test", methodName: "detectText", options: [:], success: { (_, _) in
            XCTFail("Success shouldn't have been called")
        }, error: { error in
            XCTAssertEqual("Invalid image input", error.message)
            rejected.fulfill()
        })

        plugin.detectText(call)
        wait(for: [rejected], timeout: 1)
    }
}
