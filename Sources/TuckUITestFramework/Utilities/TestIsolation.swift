import Foundation

/// Creates temporary isolated home directories for E2E test execution.
/// This prevents tests from interfering with the user's real application data.
public enum TestIsolation {

    /// Create a temporary directory structure mimicking a user HOME.
    /// Creates `Library/Application Support/` subdirectories.
    /// - Returns: The root of the temporary home directory.
    public static func createTempHome() throws -> URL {
        let tmpDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("TuckE2E_\(UUID().uuidString.prefix(8))")
        let appSupport = tmpDir
            .appendingPathComponent("Library")
            .appendingPathComponent("Application Support")
        try FileManager.default.createDirectory(at: appSupport, withIntermediateDirectories: true)
        return tmpDir
    }

    /// Recursively remove a temporary home directory.
    public static func removeTempHome(_ url: URL) throws {
        if FileManager.default.fileExists(atPath: url.path) {
            try FileManager.default.removeItem(at: url)
        }
    }

    /// Write test data to the Tuck data directory within a temp home.
    /// The data is written to `Library/Application Support/Tuck/todos.json`.
    public static func writeStore(
        todosJSON: Data,
        to tempHome: URL
    ) throws {
        let tuckDir = tempHome
            .appendingPathComponent("Library")
            .appendingPathComponent("Application Support")
            .appendingPathComponent("Tuck")
        try FileManager.default.createDirectory(at: tuckDir, withIntermediateDirectories: true)
        let todosURL = tuckDir.appendingPathComponent("todos.json")
        try todosJSON.write(to: todosURL, options: .atomic)
    }

    /// Read the todos.json from a temp home's Tuck data directory.
    public static func readStore(from tempHome: URL) throws -> Data {
        let todosURL = tempHome
            .appendingPathComponent("Library")
            .appendingPathComponent("Application Support")
            .appendingPathComponent("Tuck")
            .appendingPathComponent("todos.json")
        return try Data(contentsOf: todosURL)
    }
}
