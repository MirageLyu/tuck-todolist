import XCTest
@testable import Tuck

final class ClaudeCLIClientTests: XCTestCase {
    func testAvailabilityResponseAcceptsExactOkIgnoringCaseAndWhitespace() {
        XCTAssertTrue(ClaudeCLIClient.isExpectedAvailabilityResponse("ok"))
        XCTAssertTrue(ClaudeCLIClient.isExpectedAvailabilityResponse(" OK\n"))
    }

    func testAvailabilityResponseAcceptsOkLineWithBenignExtraOutput() {
        XCTAssertTrue(ClaudeCLIClient.isExpectedAvailabilityResponse("Claude CLI update available\nok"))
        XCTAssertTrue(ClaudeCLIClient.isExpectedAvailabilityResponse("ok.\n"))
    }

    func testAvailabilityResponseRejectsUnexpectedOutput() {
        XCTAssertFalse(ClaudeCLIClient.isExpectedAvailabilityResponse(""))
        XCTAssertFalse(ClaudeCLIClient.isExpectedAvailabilityResponse("Claude CLI available"))
    }

    func testDisplaySnippetCapsLongOutput() {
        let output = String(repeating: "a", count: 405)
        let snippet = ClaudeCLIClient.displaySnippet(output, limit: 400)
        XCTAssertEqual(snippet.count, 401)
        XCTAssertTrue(snippet.hasSuffix("…"))
    }
}
