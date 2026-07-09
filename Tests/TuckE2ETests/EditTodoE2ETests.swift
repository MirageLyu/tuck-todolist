import XCTest
@testable import TuckUITestFramework

/// E2E tests for editing todo details.
final class EditTodoE2ETests: TuckE2ETestCase {

    override func seedData() -> StoreSnapshotData? {
        return TodoItemFactory.store(with: [
            TodoItemFactory.pending(title: "Edit target"),
        ])
    }

    func testSelectTodoShowsEditor() {
        runAsync {
            let window = try await self.app.window()
            try await window.waitForReady()

            guard let row = window.todoList.row(title: "Edit target") else {
                XCTFail("Expected todo")
                return
            }
            try await row.select()
            try await Task.sleep(nanoseconds: 500_000_000)

            XCTAssertEqual(window.editor.titleText, "Edit target")
        }
    }

    func testEditorHasAllSections() {
        runAsync {
            let window = try await self.app.window()
            try await window.waitForReady()

            guard let row = window.todoList.row(title: "Edit target") else {
                XCTFail("Expected todo")
                return
            }
            try await row.select()
            try await Task.sleep(nanoseconds: 500_000_000)

            // Editor should have essential elements
            XCTAssertNotNil(window.editor.titleField, "Editor should have title field")
            XCTAssertNotNil(window.editor.priorityPicker, "Editor should have priority picker")
        }
    }
}
