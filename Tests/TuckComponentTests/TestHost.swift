import XCTest
import SwiftUI
import AppKit
@testable import Tuck
import TuckUITestFramework

/// Shared helper for component tests.
enum TestHost {

    /// Host a SwiftUI view in an NSWindow and return the window.
    /// Note: In-process AX tree is not populated in XCTest processes,
    /// so AX queries won't work. Full AX testing is done via E2E tests.
    @MainActor
    static func hostInWindow<V: View>(
        _ view: V,
        size: NSSize = NSSize(width: 400, height: 700)
    ) -> NSWindow {
        let hostingView = NSHostingView(rootView: view)
        hostingView.frame = NSRect(origin: .zero, size: size)

        let window = NSWindow(
            contentRect: NSRect(origin: .zero, size: size),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.contentView = hostingView
        window.layoutIfNeeded()
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))
        return window
    }
}
