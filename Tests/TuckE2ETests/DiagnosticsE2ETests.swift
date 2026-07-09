import XCTest
@testable import TuckUITestFramework

/// Diagnostic test to inspect the AX tree of the running app.
final class DiagnosticsE2ETests: TuckE2ETestCase {

    func testQuickCaptureInteraction() {
        runAsync(timeout: 45) {
            let window = try await self.app.window()
            try await window.waitForReady()

            print("=== Before typing: todoCount=\(window.todoList.pendingCount) ===")

            // Type and capture
            try await window.quickCapture.capture("Hello E2E")

            // Wait for the smart capture to complete
            let deadline = Date().addingTimeInterval(30)
            while Date() < deadline {
                let status = window.quickCapture.statusMessage ?? ""
                print("=== Status: '\(status)', todoCount=\(window.todoList.pendingCount) ===")
                if status != "Claude 正在整理这条待办…" && status != "Claude organizing..." && !status.isEmpty {
                    print("=== Status changed: done ===")
                    break
                }
                try await Task.sleep(nanoseconds: 1_000_000_000)
            }

            window.dumpTree(label: "AfterCapture", maxDepth: 4)
            print("=== Final: todoCount=\(window.todoList.pendingCount) ===")
        }
    }
}
