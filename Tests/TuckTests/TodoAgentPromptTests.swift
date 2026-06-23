import XCTest
@testable import Tuck

@MainActor
final class TodoAgentPromptTests: XCTestCase {
    func testBuildPromptRequestsStatusSummary() throws {
        let prompt = try TodoAgent().buildPrompt(mode: .capture, userText: "buy milk", todos: [])

        XCTAssertTrue(prompt.contains("\"statusSummary\""), prompt)
        XCTAssertTrue(prompt.contains("short user-facing progress/result summary"), prompt)
        XCTAssertTrue(prompt.contains("Do not include chain-of-thought"), prompt)
    }
}
