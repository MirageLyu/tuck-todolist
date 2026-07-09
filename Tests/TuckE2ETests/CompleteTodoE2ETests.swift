import XCTest
@testable import TuckUITestFramework

/// E2E tests for completing todos.
final class CompleteTodoE2ETests: TuckE2ETestCase {

    override func seedData() -> StoreSnapshotData? {
        return TodoItemFactory.store(with: [
            TodoItemFactory.pending(title: "To be completed"),
            TodoItemFactory.completed(title: "Already done"),
        ])
    }

    func testPendingAndCompletedSeparation() {
        runAsync {
            let window = try await self.app.window()
            try await window.waitForReady()

            // Pending todo should be visible in todo list
            XCTAssertNotNil(window.todoList.row(title: "To be completed"),
                           "Pending todo should be in the list")

            // Completed todo should NOT be in pending list
            XCTAssertNil(window.todoList.row(title: "Already done"),
                         "Completed todo should not appear in pending list")
        }
    }

    func testCompleteTodoViaRowCheck() {
        runAsync {
            let window = try await self.app.window()
            try await window.waitForReady()

            guard let row = window.todoList.row(title: "To be completed") else {
                XCTFail("Expected pending todo")
                return
            }

            // Toggle complete
            try await row.toggleComplete()
            try await Task.sleep(nanoseconds: 1_000_000_000)
            window.refresh()

            // After completion, it should disappear from pending list
            XCTAssertNil(window.todoList.row(title: "To be completed"),
                         "Completed todo should move out of pending list")
        }
    }

    func testCompletedStatusPersisted() {
        runAsync {
            let window = try await self.app.window()
            try await window.waitForReady()

            guard let row = window.todoList.row(title: "To be completed") else {
                XCTFail("Expected pending todo")
                return
            }
            try await row.toggleComplete()
            try await Task.sleep(nanoseconds: 1_000_000_000)

            // Read persisted store
            let storeData = try TestIsolation.readStore(from: self.tempHome)
            let saved = try TodoItemFactory.decode(storeData)
            let todos = saved.todos.filter { $0.title == "To be completed" }
            XCTAssertEqual(todos.count, 1)
            XCTAssertEqual(todos.first?.status, "completed")
        }
    }
}
