import XCTest
@testable import Tuck

final class QuickCapturePresentationTests: XCTestCase {
    func testIdlePresentationUsesAddLabelAndSparkles() {
        let presentation = QuickCapturePresentation(isWorking: false, strings: Strings(language: .english))

        XCTAssertEqual(presentation.buttonTitle, "Add")
        XCTAssertEqual(presentation.systemImage, "sparkles")
        XCTAssertFalse(presentation.showsProgress)
    }

    func testWorkingPresentationUsesThinkingLabelAndProgress() {
        let presentation = QuickCapturePresentation(isWorking: true, strings: Strings(language: .english))

        XCTAssertEqual(presentation.buttonTitle, "Thinking…")
        XCTAssertEqual(presentation.systemImage, "sparkles")
        XCTAssertTrue(presentation.showsProgress)
    }

    func testPreferredCaptureStatusUsesNonEmptySummary() {
        XCTAssertEqual(
            CaptureStatusSummary.preferred(summary: "Captured with a due date.", fallback: "Updated"),
            "Captured with a due date."
        )
    }

    func testPreferredCaptureStatusIgnoresWhitespaceSummary() {
        XCTAssertEqual(
            CaptureStatusSummary.preferred(summary: "   \n", fallback: "Updated"),
            "Updated"
        )
    }

    func testPreferredCaptureStatusUsesFallbackWhenSummaryMissing() {
        XCTAssertEqual(
            CaptureStatusSummary.preferred(summary: nil, fallback: "Updated"),
            "Updated"
        )
    }
}
