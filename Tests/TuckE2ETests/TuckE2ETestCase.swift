import XCTest
import Foundation
@testable import TuckUITestFramework

/// Base class for Tuck E2E tests.
/// Manages app process lifecycle, isolated data directory, and driver connection.
open class TuckE2ETestCase: XCTestCase {

    /// The driver for interacting with the Tuck app.
    public var app: TuckAppDriver!

    /// Temporary home directory that isolates the test from real user data.
    public var tempHome: URL!

    /// Path to the compiled Tuck binary.
    public var binaryURL: URL {
        let cwd = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        let candidates = [
            cwd.appendingPathComponent(".build/debug/Tuck"),
            cwd.appendingPathComponent(".build/arm64-apple-macosx/debug/Tuck"),
        ]
        for url in candidates {
            if FileManager.default.fileExists(atPath: url.path) {
                return url
            }
        }
        return cwd.appendingPathComponent(".build/debug/Tuck")
    }

    // MARK: - Setup / Teardown

    open override func setUp() {
        super.setUp()

        // Create temp home synchronously so subclasses can seed data
        tempHome = try! TestIsolation.createTempHome()

        // Subclasses can override seedData() to pre-populate store
        if let snapshot = seedData() {
            do {
                let data = try TodoItemFactory.encode(snapshot)
                try TestIsolation.writeStore(todosJSON: data, to: tempHome)
            } catch {
                XCTFail("Failed to seed store: \(error)")
            }
        }

        guard FileManager.default.fileExists(atPath: binaryURL.path) else {
            XCTFail("Tuck binary not found at \(binaryURL.path). Build first: swift build -c debug")
            return
        }

        let setupDone = XCTestExpectation(description: "E2E setup")
        Task {
            do {
                app = try await TuckAppDriver.launch(
                    binaryURL: binaryURL,
                    dataDir: tempHome,
                    arguments: ["--uitesting"]
                )
                _ = try await app.window()
            } catch {
                // Error will be surfaced in tests when app is nil
            }
            setupDone.fulfill()
        }
        wait(for: [setupDone], timeout: 30)
    }

    open override func tearDown() {
        if let app {
            app.terminate()
        }
        if let tempHome {
            try? TestIsolation.removeTempHome(tempHome)
        }
        super.tearDown()
    }

    // MARK: - Override Points

    /// Override to provide pre-seeded store data before app launch.
    /// - Returns: A store snapshot to write, or nil for empty store.
    open func seedData() -> StoreSnapshotData? {
        return TodoItemFactory.emptyStore()
    }

    // MARK: - Helpers

    /// Run an async throwing block synchronously, failing the test on error.
    public func runAsync(
        timeout: TimeInterval = 30,
        file: StaticString = #filePath,
        line: UInt = #line,
        _ block: @escaping () async throws -> Void
    ) {
        let expectation = XCTestExpectation(description: "async")
        var thrownError: Error?
        Task {
            do {
                try await block()
            } catch {
                thrownError = error
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: timeout)
        if let error = thrownError {
            XCTFail("Unexpected error: \(error)", file: file, line: line)
        }
    }
}
