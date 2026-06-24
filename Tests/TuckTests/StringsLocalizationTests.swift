import XCTest
@testable import Tuck

final class StringsLocalizationTests: XCTestCase {
    func testCaptureThinkingStringsEnglish() {
        let strings = Strings(language: .english)

        XCTAssertEqual(strings.captureThinking, "Thinking…")
        XCTAssertEqual(strings.captureThinkingStatus, "Claude is organizing this todo…")
    }

    func testCaptureThinkingStringsChinese() {
        let strings = Strings(language: .zhHans)

        XCTAssertEqual(strings.captureThinking, "思考中…")
        XCTAssertEqual(strings.captureThinkingStatus, "Claude 正在整理这条待办…")
    }
}
