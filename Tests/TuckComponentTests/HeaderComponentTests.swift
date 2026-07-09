import XCTest
import SwiftUI
@testable import Tuck

/// Component tests for the Header area.
final class HeaderComponentTests: XCTestCase {

    @MainActor
    func testHeaderRendersWithoutCrash() {
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
    }

    @MainActor
    func testHeaderWithMultipleTodosDoesNotCrash() {
        let store = TodoStore()
        store.todos = []
        for i in 1...10 {
            var item = TodoItem(title: "Task \(i)")
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
    }

    @MainActor
    func testHeaderWithEmptyStoreDoesNotCrash() {
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
    }
}
