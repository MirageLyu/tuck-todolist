import Foundation

/// Lightweight factory for creating `TodoItem`-compatible JSON data
/// for E2E test scenarios. The framework does not depend on the Tuck module,
/// so E2E tests prepopulate `todos.json` using these structures.

// MARK: - Test Data Types

/// JSON-compatible representation of a TodoItem for test data seeding.
public struct TodoItemData: Codable {
    public var id: String
    public var title: String
    public var notes: String
    public var status: String
    public var priority: String
    public var dueDate: String?
    public var tags: [String]
    public var progressEntries: [ProgressEntryData]
    public var createdAt: String
    public var updatedAt: String

    public init(
        id: String = UUID().uuidString,
        title: String,
        notes: String = "",
        status: String = "pending",
        priority: String = "normal",
        dueDate: String? = nil,
        tags: [String] = [],
        progressEntries: [ProgressEntryData] = [],
        createdAt: String = ISO8601DateFormatter().string(from: Date()),
        updatedAt: String = ISO8601DateFormatter().string(from: Date())
    ) {
        self.id = id
        self.title = title
        self.notes = notes
        self.status = status
        self.priority = priority
        self.dueDate = dueDate
        self.tags = tags
        self.progressEntries = progressEntries
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

/// JSON-compatible progress entry.
public struct ProgressEntryData: Codable {
    public var id: String
    public var content: String
    public var createdAt: String

    public init(
        id: String = UUID().uuidString,
        content: String,
        createdAt: String = ISO8601DateFormatter().string(from: Date())
    ) {
        self.id = id
        self.content = content
        self.createdAt = createdAt
    }
}

/// Top-level store snapshot matching what TodoStore writes to todos.json.
public struct StoreSnapshotData: Codable {
    public var todos: [TodoItemData]
    public var chatMessages: [ChatMessageData]

    public init(todos: [TodoItemData], chatMessages: [ChatMessageData] = []) {
        self.todos = todos
        self.chatMessages = chatMessages
    }
}

/// JSON-compatible chat message.
public struct ChatMessageData: Codable {
    public var id: String
    public var role: String
    public var text: String
    public var createdAt: String

    public init(
        id: String = UUID().uuidString,
        role: String = "assistant",
        text: String = "Hello",
        createdAt: String = ISO8601DateFormatter().string(from: Date())
    ) {
        self.id = id
        self.role = role
        self.text = text
        self.createdAt = createdAt
    }
}

// MARK: - Factory

public enum TodoItemFactory {

    private static let formatter: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()

    /// A simple pending todo with just a title.
    public static func pending(title: String) -> TodoItemData {
        TodoItemData(title: title, status: "pending", priority: "normal")
    }

    /// A completed todo.
    public static func completed(title: String) -> TodoItemData {
        TodoItemData(title: title, status: "completed", priority: "normal")
    }

    /// A high-priority todo.
    public static func highPriority(title: String) -> TodoItemData {
        TodoItemData(title: title, status: "pending", priority: "high")
    }

    /// A todo with a due date `daysFromNow` days in the future.
    public static func withDueDate(
        title: String,
        daysFromNow: Int,
        priority: String = "normal"
    ) -> TodoItemData {
        let due = Calendar.current.date(byAdding: .day, value: daysFromNow, to: Date())!
        let dueString = formatter.string(from: due)
        return TodoItemData(title: title, status: "pending", priority: priority, dueDate: dueString)
    }

    /// A completed todo with progress entries.
    public static func withProgress(title: String, entries: [String]) -> TodoItemData {
        let progress = entries.map { ProgressEntryData(content: $0) }
        return TodoItemData(title: title, status: "pending", progressEntries: progress)
    }

    /// Create an empty store snapshot.
    public static func emptyStore() -> StoreSnapshotData {
        StoreSnapshotData(todos: [])
    }

    /// Create a store snapshot from todo data items.
    public static func store(with todos: [TodoItemData]) -> StoreSnapshotData {
        StoreSnapshotData(todos: todos)
    }

    /// Encode a store snapshot to JSON data.
    public static func encode(_ snapshot: StoreSnapshotData) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(snapshot)
    }

    /// Decode a store snapshot from JSON data.
    public static func decode(_ data: Data) throws -> StoreSnapshotData {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(StoreSnapshotData.self, from: data)
    }
}
