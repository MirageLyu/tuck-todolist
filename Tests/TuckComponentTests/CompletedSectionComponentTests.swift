import XCTest
import SwiftUI
@testable import Tuck

/// Component tests for the Completed section.
final class CompletedSectionComponentTests: XCTestCase {

    @MainActor
    func testCompletedSectionEmptyWhenNoCompleted() {
        let store = TodoStore()
        store.todos = []
        store.addTodo(title: "Pending")
        store.addTodo(title: "Another pending")
        let settings = AppSettings()
        let hostingView = NSHostingView(rootView: MenuBarView(store: store, settings: settings).frame(width: 400, height: 700))
        hostingView.frame = NSRect(x: 0, y: 0, width: 400, height: 700)
        let window = NSWindow(contentRect: hostingView.bounds, styleMask: [.titled], backing: .buffered, defer: false)
        window.contentView = hostingView
        window.layoutIfNeeded()
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))
        XCTAssertNotNil(window.contentView)
        XCTAssertEqual(store.completedTodos.count, 0)
    }

    @MainActor
    func testCompletedSectionShowsCompletedTodos() {
        let store = TodoStore()
        store.todos = []
        store.addTodo(title: "Done 1")
        store.addTodo(title: "Done 2")
        for todo in store.todos {
            store.setCompleted(todo, completed: true)
        }
        let settings = AppSettings()
        let hostingView = NSHostingView(rootView: MenuBarView(store: store, settings: settings).frame(width: 400, height: 700))
        hostingView.frame = NSRect(x: 0, y: 0, width: 400, height: 700)
        let window = NSWindow(contentRect: hostingView.bounds, styleMask: [.titled], backing: .buffered, defer: false)
        window.contentView = hostingView
        window.layoutIfNeeded()
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))
        XCTAssertNotNil(window.contentView)
        XCTAssertEqual(store.completedTodos.count, 2)
    }

    @MainActor
    func testSetCompletedTogglesStatus() {
        let store = TodoStore()
        store.todos = []
        store.addTodo(title: "Toggle me")
        guard let todo = store.todos.first else {
            XCTFail("Expected a todo")
            return
        }
        XCTAssertEqual(todo.status, .pending)

        store.setCompleted(todo, completed: true)
        XCTAssertEqual(store.todos.first?.status, .completed)

        store.setCompleted(todo, completed: false)
        XCTAssertEqual(store.todos.first?.status, .pending)
    }
}
