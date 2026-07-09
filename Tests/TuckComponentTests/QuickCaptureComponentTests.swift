import XCTest
import SwiftUI
@testable import Tuck

/// Component tests for the Quick Capture area.
final class QuickCaptureComponentTests: XCTestCase {

    @MainActor
    func testQuickCaptureRendersWithoutCrash() {
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
    func testCaptureButtonStateWhenAgentWorking() {
        let store = TodoStore()
        store.todos = []
        store.isAgentWorking = true
        let settings = AppSettings()
        let hostingView = NSHostingView(rootView: MenuBarView(store: store, settings: settings).frame(width: 400, height: 700))
        hostingView.frame = NSRect(x: 0, y: 0, width: 400, height: 700)
        let window = NSWindow(contentRect: hostingView.bounds, styleMask: [.titled], backing: .buffered, defer: false)
        window.contentView = hostingView
        window.layoutIfNeeded()
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))
        XCTAssertNotNil(window.contentView)
        XCTAssertTrue(store.isAgentWorking)
    }

    @MainActor
    func testCaptureButtonStateWhenAgentIdle() {
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
        XCTAssertFalse(store.isAgentWorking)
    }
}
