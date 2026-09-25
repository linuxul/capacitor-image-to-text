import XCTest
import UIKit
import Capacitor
@testable import CapacitorOcrPlugin

class CapacitorOcrPluginTests: XCTestCase {
    func testDetectTextIsRegisteredAsAPromiseMethod() {
        let plugin = CapacitorOcr()

        XCTAssertEqual(["detectText"], plugin.pluginMethods.map { $0.name })
        XCTAssertEqual([.promise], plugin.pluginMethods.map { $0.returnType })
    }

    func testDetectTextRejectsCallsWithoutAnImage() {
        let cases: [(options: JSObject, message: String)] = [
            ([:], "Invalid image input"),
            (["base64": "data:image/png;base64,not an image"], "Could not load image from base64"),
            (["filename": "file:///no/such/image.png"], "Could not load image from path")
        ]
        for (options, message) in cases {
            let call = CAPPluginCall(callbackId: "test", methodName: "detectText", options: options, success: { _, _ in
                XCTFail("Success shouldn't have been called")
            }, error: { _ in
                XCTFail("detectText answers by throwing")
            })

            XCTAssertThrowsError(try CapacitorOcr().detectText(call)) { error in
                // The bridge rejects the call with this message and no code, as the method did before.
                XCTAssertEqual((error as? CAPPluginError)?.message, message)
                XCTAssertNil((error as? CAPPluginError)?.code)
            }
        }
    }

    func testDetectTextResolvesWithTheTextOfTheImage() throws {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let image = UIGraphicsImageRenderer(size: CGSize(width: 800, height: 200), format: format).image { context in
            UIColor.white.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 800, height: 200))
            ("Capacitor" as NSString).draw(at: CGPoint(x: 40, y: 50), withAttributes: [
                .font: UIFont.boldSystemFont(ofSize: 80),
                .foregroundColor: UIColor.black
            ])
        }
        let base64 = try XCTUnwrap(image.pngData()).base64EncodedString()
        let resolved = expectation(description: "detectText resolves")
        var detections: [[String: Any]] = []
        let call = CAPPluginCall(callbackId: "test", methodName: "detectText", options: ["base64": base64], success: { result, _ in
            detections = result.data?["textDetections"] as? [[String: Any]] ?? []
            resolved.fulfill()
        }, error: { error in
            XCTFail("detectText rejected: \(error.message)")
            resolved.fulfill()
        })

        // The method returns before the recognition, which answers the call from the main queue.
        try CapacitorOcr().detectText(call)
        wait(for: [resolved], timeout: 20)

        let texts = detections.compactMap { $0["text"] as? String }
        XCTAssertTrue(texts.contains { $0.lowercased().contains("capacitor") }, "\(texts)")
        XCTAssertNotNil(detections.first?["topLeft"] as? [Double])
    }
}
