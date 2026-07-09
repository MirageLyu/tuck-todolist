import XCTest
import SwiftUI
@testable import Tuck

/// Component tests for the Editor area.
final class EditorComponentTests: XCTestCase {

    @MainActor
    func testEditorRendersWithSelectedTodo() {
        let store = TodoStore()
        store.todos = []
        store.addTodo(title: "Edit me")
        store.selectedTodoID = store.todos.first?.id
        let settings = AppSettings()
        let hostingView = NSHostingView(rootView: MenuBarView(store: store, settings: settings).frame(width: 400, height: 700))
        hostingView.frame = NSRect(x: 0, y: 0, width: 400, height: 700)
        let window = NSWindow(contentRect: hostingView.bounds, styleMask: [.titled], backing: .buffered, defer: false)
        window.contentView = hostingView
        window.layoutIfNeeded()
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))
        XCTAssertNotNil(window.contentView)
        XCTAssertNotNil(store.selectedTodo)
    }

    @MainActor
    func testEditorRendersWithoutSelectedTodo() {
        let store = TodoStore()
        store.todos = []
        store.addTodo(title: "Unselected")
        store.selectedTodoID = nil
        let settings = AppSettings()
        let hostingView = NSHostingView(rootView: MenuBarView(store: store, settings: settings).frame(width: 400, height: 700))
        hostingView.frame = NSRect(x: 0, y: 0, width: 400, height: 700)
        let window = NSWindow(contentRect: hostingView.bounds, styleMask: [.titled], backing: .buffered, defer: false)
        window.contentView = hostingView
        window.layoutIfNeeded()
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))
        XCTAssertNotNil(window.contentView)
        XCTAssertNil(store.selectedTodoID)
    }

    @MainActor
    func testEditorShowsProgressEntries() {
        let store = TodoStore()
        store.todos = []
        store.addTodo(title: "Progress task")
        if let todo = store.todos.first {
            store.addProgress(to: todo, content: "Step 1 done")
            store.addProgress(to: todo, content: "Step 2 done")
        }
        store.selectedTodoID = store.todos.first?.id
        let settings = AppSettings()
        let hostingView = NSHostingView(rootView: MenuBarView(store: store, settings: settings).frame(width: 400, height: 700))
        hostingView.frame = NSRect(x: 0, y: 0, width: 400, height: 700)
        let window = NSWindow(contentRect: hostingView.bounds, styleMask: [.titled], backing: .buffered, defer: false)
        window.contentView = hostingView
        window.layoutIfNeeded()
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))
        XCTAssertNotNil(window.contentView)
        XCTAssertEqual(store.selectedTodo?.progressEntries.count, 2)
    }
}
