import XCTest
@testable import Tuck

final class AgentResponseTests: XCTestCase {
    func testDecodeAgentResponseWithStatusSummary() throws {
        let json = """
        {
          "reply": "Added it.",
          "statusSummary": "Captured with a due date.",
          "actions": []
        }
        """
        let data = try XCTUnwrap(json.data(using: .utf8))

        let response = try JSONDecoder().decode(AgentResponse.self, from: data)

        XCTAssertEqual(response.reply, "Added it.")
        XCTAssertEqual(response.statusSummary, "Captured with a due date.")
        XCTAssertTrue(response.actions.isEmpty)
        XCTAssertNil(response.dailySummary)
    }

    func testDecodeAgentResponseWithoutStatusSummaryRemainsCompatible() throws {
        let json = """
        {
          "reply": "Added it.",
          "actions": []
        }
        """
        let data = try XCTUnwrap(json.data(using: .utf8))

        let response = try JSONDecoder().decode(AgentResponse.self, from: data)

        XCTAssertEqual(response.reply, "Added it.")
        XCTAssertNil(response.statusSummary)
        XCTAssertTrue(response.actions.isEmpty)
    }
}
