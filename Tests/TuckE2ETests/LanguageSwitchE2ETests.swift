import XCTest
@testable import TuckUITestFramework

/// E2E tests for header, footer, and UI chrome.
final class MiscE2ETests: TuckE2ETestCase {

    func testHeaderAndFooterExist() {
        runAsync {
            let window = try await self.app.window()
            try await window.waitForReady()

            XCTAssertNotNil(window.header.titleElement, "Header title should exist")
            XCTAssertNotNil(window.header.languageButton, "Language button should exist")
            XCTAssertNotNil(window.footer.summaryText, "Footer summary should exist")
            XCTAssertNotNil(window.footer.quitButton, "Quit button should exist")
        }
    }

    func testLanguageButtonIsInteractive() {
        runAsync {
            let window = try await self.app.window()
            try await window.waitForReady()

            guard let languageButton = window.header.languageButton else {
                XCTFail("Language button not found")
                return
            }

            XCTAssertTrue(languageButton.isEnabled, "Language button should be enabled")

            try await window.header.cycleLanguage()
            try await Task.sleep(nanoseconds: 300_000_000)

            XCTAssertTrue(languageButton.isEnabled, "Language button should remain enabled after cycling")
        }
    }

    func testQuickCaptureUIElementsExist() {
        runAsync {
            let window = try await self.app.window()
            try await window.waitForReady()

            XCTAssertNotNil(window.quickCapture.textField, "Quick capture text field should exist")
            XCTAssertNotNil(window.quickCapture.captureButton, "Capture button should exist")
        }
    }

    func testEmptyStateWithNoTodos() {
        runAsync {
            let window = try await self.app.window()
            try await window.waitForReady()

            // Empty store (default seedData) should show empty state
            XCTAssertEqual(window.todoList.pendingCount, 0)
            XCTAssertTrue(window.todoList.isEmpty)
            XCTAssertNotNil(window.todoList.emptyLabel, "Should show empty state label")
        }
    }
}
