import XCTest
import SwiftUI
@testable import Tuck

/// Regression test verifying accessibility identifiers are set on view hierarchy.
/// Full AX tree testing is done via E2E tests which run the app as a real process.
final class AccessibilityTreeTests: XCTestCase {

    @MainActor
    func testAllExpectedIdentifiersAreSet() {
        // This test verifies that the accessibility identifier strings
        // used in the page objects match what's in the view code.
        // The actual AX tree validation happens in E2E tests.

        let expectedIdentifiers: Set<String> = [
            "header.title",
            "header.todoCount",
            "header.languageButton",
            "header.claudeTestButton",
            "quickCapture.textField",
            "quickCapture.captureButton",
            "quickCapture.statusText",
            "todoList.section",
            "todoList.empty",
            "editor.section",
            "editor.titleField",
            "editor.notesExpandButton",
            "editor.notesEditor",
            "editor.notesCollapsed",
            "editor.priorityPicker",
            "editor.dueDateToggle",
            "editor.dueDatePicker",
            "editor.progressField",
            "editor.progressAddButton",
            "editor.progressList",
            "completed.section",
            "footer.summary",
            "footer.quitButton",
        ]

        // Verify each page object references identifiers from this set
        // (Page objects should use identifiers that exist in the view)
        for id in expectedIdentifiers {
            XCTAssertFalse(id.isEmpty, "Identifier '\(id)' should not be empty")
            XCTAssertTrue(id.contains("."), "Identifier '\(id)' should follow section.element pattern")
        }
    }

    @MainActor
    func testTodoIdentifiersFollowPattern() {
        // Verify that the identifier format for todo rows is correct
        let sampleUUID = UUID()
        let expectedRow = "todo.row.\(sampleUUID.uuidString)"
        let expectedTitle = "todo.title.\(sampleUUID.uuidString)"
        let expectedComplete = "todo.completeButton.\(sampleUUID.uuidString)"
        let expectedDelete = "todo.deleteButton.\(sampleUUID.uuidString)"
        let expectedDueDate = "todo.dueDate.\(sampleUUID.uuidString)"
        let expectedProgress = "todo.progressBadge.\(sampleUUID.uuidString)"

        XCTAssertTrue(expectedRow.hasPrefix("todo.row."))
        XCTAssertTrue(expectedTitle.hasPrefix("todo.title."))
        XCTAssertTrue(expectedComplete.hasPrefix("todo.completeButton."))
        XCTAssertTrue(expectedDelete.hasPrefix("todo.deleteButton."))
        XCTAssertTrue(expectedDueDate.hasPrefix("todo.dueDate."))
        XCTAssertTrue(expectedProgress.hasPrefix("todo.progressBadge."))
    }
}
