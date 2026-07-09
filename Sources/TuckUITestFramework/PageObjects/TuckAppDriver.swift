import AppKit
import Foundation

/// Top-level driver that manages the Tuck app lifecycle for E2E testing.
/// Launches the app binary as a subprocess, connects via Accessibility API,
/// and provides access to the window-level page object.
public class TuckAppDriver {
    public let process: Process
    public let binaryURL: URL
    public let dataDir: URL

    /// The accessibility element for the Tuck application.
    public private(set) var appElement: AXElement

    private init(process: Process, binaryURL: URL, dataDir: URL, appElement: AXElement) {
        self.process = process
        self.binaryURL = binaryURL
        self.dataDir = dataDir
        self.appElement = appElement
    }

    // MARK: - Launch

    /// Launch Tuck binary with an isolated data directory for testing.
    /// - Parameters:
    ///   - binaryURL: Path to the compiled Tuck binary (e.g. `.build/debug/Tuck`).
    ///   - dataDir: A temp directory to use as HOME (isolates Application Support).
    ///   - arguments: Additional command-line arguments.
    ///   - timeout: Maximum time to wait for the app to become accessible.
    /// - Returns: A configured `TuckAppDriver` instance.
    public static func launch(
        binaryURL: URL,
        dataDir: URL,
        arguments: [String] = [],
        timeout: TimeInterval = 15.0
    ) async throws -> TuckAppDriver {
        // Check that binary exists
        guard FileManager.default.fileExists(atPath: binaryURL.path) else {
            throw AXError.elementNotFound(description: "Tuck binary not found at \(binaryURL.path). Build first with: swift build -c debug")
        }

        // Check accessibility permission
        guard AXEngine.hasPermission else {
            throw AXError.actionFailed(
                action: "launch",
                code: -1
            )
        }

        let process = Process()
        process.executableURL = binaryURL
        var allArgs = arguments.contains("--uitesting") ? arguments : arguments + ["--uitesting"]

        // Build the Tuck data directory path and pass via --data-dir
        let tuckDataDir = dataDir
            .appendingPathComponent("Library")
            .appendingPathComponent("Application Support")
            .appendingPathComponent("Tuck")
        try FileManager.default.createDirectory(at: tuckDataDir, withIntermediateDirectories: true)
        allArgs += ["--data-dir", tuckDataDir.path]

        process.arguments = allArgs

        // Pass environment (without overriding HOME, since --data-dir handles isolation)
        process.environment = ProcessInfo.processInfo.environment

        // Capture stderr for diagnostics
        let stderrPipe = Pipe()
        process.standardError = stderrPipe

        try process.run()

        // Wait for the app to appear in the accessibility tree
        let deadline = Date().addingTimeInterval(timeout)
        var appElement: AXElement?

        while Date() < deadline {
            let apps = NSWorkspace.shared.runningApplications
            if let tuckApp = apps.first(where: { $0.processIdentifier == process.processIdentifier }),
               !tuckApp.isTerminated {
                let axApp = AXEngine.app(for: process.processIdentifier)
                // Check if the app has at least one window
                if axApp.children.contains(where: { $0.role == kAXWindowRole }) {
                    appElement = axApp
                    break
                }
            }
            try await Task.sleep(nanoseconds: 500_000_000)
        }

        guard let appEl = appElement else {
            process.terminate()
            // Read stderr for diagnostics
            let stderrData = stderrPipe.fileHandleForReading.readDataToEndOfFile()
            let stderr = String(data: stderrData, encoding: .utf8) ?? ""
            throw AXError.timeout(description: "Tuck app did not become accessible within \(timeout)s. stderr: \(stderr.prefix(200))")
        }

        AXEngine.configureTimeout(for: appEl, seconds: 3.0)

        return TuckAppDriver(
            process: process,
            binaryURL: binaryURL,
            dataDir: dataDir,
            appElement: appEl
        )
    }

    // MARK: - Connect

    /// Connect to an already-running Tuck process by PID.
    public static func connect(pid: pid_t) async throws -> TuckAppDriver {
        let appEl = AXEngine.app(for: pid)
        AXEngine.configureTimeout(for: appEl, seconds: 3.0)

        // We don't have the original process/binaryURL/dataDir but we can still interact
        return TuckAppDriver(
            process: Process(), // placeholder
            binaryURL: URL(fileURLWithPath: ""),
            dataDir: URL(fileURLWithPath: ""),
            appElement: appEl
        )
    }

    // MARK: - Window Access

    /// Get the main window as a `MenuBarWindow` page object.
    /// In `--uitesting` mode, this returns the WindowGroup window.
    @discardableResult
    public func window() async throws -> MenuBarWindow {
        // Look for the window containing Tuck content
        let windows = appElement.children.filter { $0.role == kAXWindowRole }

        if let win = windows.first(where: { $0.title?.contains("Tuck") == true }) {
            return MenuBarWindow(windowElement: win)
        }

        // Fallback: use any accessible window
        if let win = windows.first {
            return MenuBarWindow(windowElement: win)
        }

        // Wait for a window to appear
        let deadline = Date().addingTimeInterval(5)
        while Date() < deadline {
            let refreshedWindows = appElement.children.filter { $0.role == kAXWindowRole }
            if let win = refreshedWindows.first {
                return MenuBarWindow(windowElement: win)
            }
            try await Task.sleep(nanoseconds: 500_000_000)
        }

        throw AXError.elementNotFound(description: "No window found for Tuck app")
    }

    // MARK: - App Control

    /// Bring the app to the front.
    public func activate() {
        AXUIElementSetAttributeValue(
            appElement.raw,
            kAXFrontmostAttribute as CFString,
            kCFBooleanTrue!
        )
    }

    /// Terminate the app process. Sends SIGTERM, waits up to 5s, then SIGKILL.
    public func terminate() {
        guard process.isRunning else { return }
        process.terminate()

        // Give it a moment to exit gracefully
        let deadline = Date().addingTimeInterval(5)
        while process.isRunning && Date() < deadline {
            Thread.sleep(forTimeInterval: 0.1)
        }

        if process.isRunning {
            // Force kill if still running
            kill(process.processIdentifier, SIGKILL)
        }
    }

    /// Whether the app process is still running.
    public var isRunning: Bool {
        process.isRunning
    }

    /// The PID of the app process.
    public var pid: pid_t {
        process.processIdentifier
    }

    // MARK: - Data Access

    /// Read the todos.json from the isolated data directory.
    public func readStoreJSON() throws -> Data {
        let url = dataDir
            .appendingPathComponent("Library")
            .appendingPathComponent("Application Support")
            .appendingPathComponent("Tuck")
            .appendingPathComponent("todos.json")
        return try Data(contentsOf: url)
    }

    /// Write todos.json to the isolated data directory (for test setup before launch).
    public static func writeStoreJSON(_ data: Data, to dataDir: URL) throws {
        let tuckDir = dataDir
            .appendingPathComponent("Library")
            .appendingPathComponent("Application Support")
            .appendingPathComponent("Tuck")
        try FileManager.default.createDirectory(at: tuckDir, withIntermediateDirectories: true)
        let url = tuckDir.appendingPathComponent("todos.json")
        try data.write(to: url, options: .atomic)
    }

    // MARK: - Teardown

    deinit {
        if process.isRunning {
            process.terminate()
        }
    }
}
