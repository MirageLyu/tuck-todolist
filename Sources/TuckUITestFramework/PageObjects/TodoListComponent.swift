import AppKit

/// Page object for the todo list area: section container, rows, empty state.
public class TodoListComponent {
    public let root: AXElement

    public init(root: AXElement) {
        self.root = root
    }

    // MARK: - Child Elements

    public var emptyLabel: AXElement? {
        root.first(identifier: "todoList.empty")
    }

    // MARK: - Properties

    public var isEmpty: Bool {
        emptyLabel != nil
    }

    public var pendingCount: Int {
        allRowIDs().count
    }

    // MARK: - Row Access

    /// Extract todo UUIDs from todo element identifiers scattered in the window.
    public func allRowIDs() -> [String] {
        let prefixes = ["todo.title.", "todo.completeButton.", "todo.deleteButton.", "todo.dueDate.", "todo.progressBadge.", "todo.row."]
        var ids = Set<String>()
        for prefix in prefixes {
            for el in root.descendants(identifierHasPrefix: prefix) {
                guard let identifier = el.identifier else { continue }
                let uuid = String(identifier.dropFirst(prefix.count))
                if !uuid.isEmpty {
                    ids.insert(uuid)
                }
            }
        }
        return Array(ids)
    }

    /// Get all todo rows currently visible.
    public func allRows() -> [TodoRowComponent] {
        allRowIDs().compactMap { row(id: $0) }
    }

    /// Get a specific row by todo UUID.
    public func row(id: String) -> TodoRowComponent? {
        // Check if any descendant has a matching identifier suffix
        let hasMatchingChild = root.descendants(identifierHasPrefix: "todo.title.\(id)").count > 0
            || root.descendants(identifierHasPrefix: "todo.completeButton.\(id)").count > 0
            || root.descendants(identifierHasPrefix: "todo.row.\(id)").count > 0
        guard hasMatchingChild else { return nil }
        return TodoRowComponent(root: root, todoID: id)
    }

    /// Find a row by todo title text.
    public func row(title: String) -> TodoRowComponent? {
        allRows().first { $0.title == title }
    }

    /// Wait for a row with the given title to appear.
    @discardableResult
    public func waitForRow(title: String, timeout: TimeInterval = 5) async throws -> TodoRowComponent {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if let row = row(title: title) { return row }
            try await Task.sleep(nanoseconds: 200_000_000)
        }
        throw AXError.timeout(description: "TodoList row with title '\(title)'")
    }

    /// Wait for a row with the given ID to appear.
    @discardableResult
    public func waitForRow(id: String, timeout: TimeInterval = 5) async throws -> TodoRowComponent {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if let row = row(id: id) { return row }
            try await Task.sleep(nanoseconds: 200_000_000)
        }
        throw AXError.timeout(description: "TodoList row with id '\(id)'")
    }
}
