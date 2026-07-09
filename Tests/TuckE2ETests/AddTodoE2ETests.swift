import XCTest
@testable import TuckUITestFramework

/// E2E tests for todo list rendering with pre-populated data.
final class TodoListE2ETests: TuckE2ETestCase {

    override func seedData() -> StoreSnapshotData? {
        return TodoItemFactory.store(with: [
            TodoItemFactory.pending(title: "Buy groceries"),
            TodoItemFactory.pending(title: "Walk the dog"),
            TodoItemFactory.pending(title: "Read a book"),
        ])
    }

    func testPrepopulatedTodosRender() {
        runAsync {
            let window = try await self.app.window()
            try await window.waitForReady()

            window.dumpTree(label: "TodoList", maxDepth: 3)
        }
    }

    func testTodoRowElementsExist() {
        runAsync {
            let window = try await self.app.window()
            try await window.waitForReady()

            guard let row = window.todoList.row(title: "Buy groceries") else {
                XCTFail("Expected row")
                return
            }

            // Row should have title, complete button, and delete button
            XCTAssertEqual(row.title, "Buy groceries")
            XCTAssertNotNil(row.completeButton, "Should have complete button")
            XCTAssertNotNil(row.deleteButton, "Should have delete button")
        }
    }

    func testHeaderCountMatchesTodoCount() {
        runAsync {
            let window = try await self.app.window()
            try await window.waitForReady()

            // Header count should match pending count
            let countText = window.header.todoCount
            let pending = window.todoList.pendingCount
            XCTAssertEqual(countText, "\(pending)", "Header count should match pending count")
        }
    }

    func testSelectTodoShowsEditor() {
        runAsync {
            let window = try await self.app.window()
            try await window.waitForReady()

            guard let row = window.todoList.row(title: "Buy groceries") else {
                XCTFail("Expected row")
                return
            }
            try await row.select()
            try await Task.sleep(nanoseconds: 500_000_000)

            // Editor should show the selected todo's title
            XCTAssertEqual(window.editor.titleText, "Buy groceries")
        }
    }
}
