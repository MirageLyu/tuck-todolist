import XCTest
@testable import TuckUITestFramework

/// E2E tests for deleting todos.
final class DeleteTodoE2ETests: TuckE2ETestCase {

    override func seedData() -> StoreSnapshotData? {
        return TodoItemFactory.store(with: [
            TodoItemFactory.pending(title: "Delete me"),
            TodoItemFactory.pending(title: "Keep me"),
        ])
    }

    func testTodosAreRenderedCorrectly() {
        runAsync {
            let window = try await self.app.window()
            try await window.waitForReady()

            XCTAssertEqual(window.todoList.pendingCount, 2, "Should have 2 todos")
        }
    }

    func testDeleteButtonExists() {
        runAsync {
            let window = try await self.app.window()
            try await window.waitForReady()

            guard let row = window.todoList.row(title: "Delete me") else {
                XCTFail("Expected todo")
                return
            }

            XCTAssertNotNil(row.deleteButton, "Should have delete button")
        }
    }
}
