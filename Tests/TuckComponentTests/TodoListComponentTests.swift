import XCTest
import SwiftUI
@testable import Tuck

/// Component tests for the Todo List area.
final class TodoListComponentTests: XCTestCase {

    @MainActor
    func testTodoListRendersWithEmptyStore() {
        let store = TodoStore()
        store.todos = []
        let settings = AppSettings()
        let hostingView = NSHostingView(rootView: MenuBarView(store: store, settings: settings).frame(width: 400, height: 700))
        hostingView.frame = NSRect(x: 0, y: 0, width: 400, height: 700)
        let window = NSWindow(contentRect: hostingView.bounds, styleMask: [.titled], backing: .buffered, defer: false)
        window.contentView = hostingView
        window.layoutIfNeeded()
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))
        XCTAssertNotNil(window.contentView)
        XCTAssertEqual(store.pendingTodos.count, 0)
    }

    @MainActor
    func testTodoListRendersWithMultipleTodos() {
        let store = TodoStore()
        store.todos = []
        for i in 1...5 {
            store.addTodo(title: "Task \(i)")
        }
        let settings = AppSettings()
        let hostingView = NSHostingView(rootView: MenuBarView(store: store, settings: settings).frame(width: 400, height: 700))
        hostingView.frame = NSRect(x: 0, y: 0, width: 400, height: 700)
        let window = NSWindow(contentRect: hostingView.bounds, styleMask: [.titled], backing: .buffered, defer: false)
        window.contentView = hostingView
        window.layoutIfNeeded()
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))
        XCTAssertNotNil(window.contentView)
        XCTAssertEqual(store.pendingTodos.count, 5)
    }

    @MainActor
    func testTodoListWithMoreThanMaxDisplay() {
        let store = TodoStore()
        store.todos = []
        for i in 1...10 {
            store.addTodo(title: "Task \(i)")
        }
        let settings = AppSettings()
        let hostingView = NSHostingView(rootView: MenuBarView(store: store, settings: settings).frame(width: 400, height: 700))
        hostingView.frame = NSRect(x: 0, y: 0, width: 400, height: 700)
        let window = NSWindow(contentRect: hostingView.bounds, styleMask: [.titled], backing: .buffered, defer: false)
        window.contentView = hostingView
        window.layoutIfNeeded()
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))
        XCTAssertNotNil(window.contentView)
        // UI only shows 6 max, but store has all 10
        XCTAssertEqual(store.pendingTodos.count, 10)
    }

    @MainActor
    func testSetCompletedMovesTodoBetweenSections() {
        let store = TodoStore()
        store.todos = []
        store.addTodo(title: "Task 1")
        store.addTodo(title: "Task 2")
        XCTAssertEqual(store.pendingTodos.count, 2)
        XCTAssertEqual(store.completedTodos.count, 0)

        guard let todo = store.todos.first else {
            XCTFail("Expected a todo")
            return
        }
        store.setCompleted(todo, completed: true)
        XCTAssertEqual(store.pendingTodos.count, 1)
        XCTAssertEqual(store.completedTodos.count, 1)
    }
}
