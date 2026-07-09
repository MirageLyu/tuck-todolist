import AppKit

/// Page object for a single todo row: title, completion toggle, progress badge, delete button.
public class TodoRowComponent {
    public let root: AXElement
    public let todoID: String

    public init(root: AXElement, todoID: String) {
        self.root = root
        self.todoID = todoID
    }

    // MARK: - Child Elements

    public var titleElement: AXElement? {
        root.first(identifier: "todo.title.\(todoID)")
    }

    public var completeButton: AXElement? {
        root.first(identifier: "todo.completeButton.\(todoID)")
    }

    public var dueDateElement: AXElement? {
        root.first(identifier: "todo.dueDate.\(todoID)")
    }

    public var progressBadge: AXElement? {
        root.first(identifier: "todo.progressBadge.\(todoID)")
    }

    public var deleteButton: AXElement? {
        root.first(identifier: "todo.deleteButton.\(todoID)")
    }

    // MARK: - Properties

    public var title: String? {
        titleElement?.title ?? titleElement?.stringValue
    }

    public var dueDateText: String? {
        dueDateElement?.title ?? dueDateElement?.stringValue
    }

    public var isCompleted: Bool {
        // Check if the complete button shows the filled checkmark
        completeButton?.title?.contains("checkmark.circle.fill") ?? false
            || completeButton?.help?.contains("completed") ?? false
    }

    public var hasProgress: Bool {
        progressBadge != nil
    }

    // MARK: - Actions

    @discardableResult
    public func toggleComplete() async throws -> TodoRowComponent {
        guard let btn = completeButton else {
            throw AXError.elementNotFound(description: "Todo completeButton \(todoID)")
        }
        try btn.press()
        try await Task.sleep(nanoseconds: 200_000_000)
        return self
    }

    @discardableResult
    public func select() async throws -> TodoRowComponent {
        guard let titleEl = titleElement else {
            // Fallback: click the row itself
            try root.press()
            try await Task.sleep(nanoseconds: 100_000_000)
            return self
        }
        try titleEl.press()
        try await Task.sleep(nanoseconds: 100_000_000)
        return self
    }

    @discardableResult
    public func clickDelete() async throws -> TodoRowComponent {
        guard let btn = deleteButton else {
            throw AXError.elementNotFound(description: "Todo deleteButton \(todoID)")
        }
        try btn.press()
        try await Task.sleep(nanoseconds: 200_000_000)
        return self
    }

    @discardableResult
    public func confirmDelete() async throws -> TodoRowComponent {
        // After clicking delete, the button changes to a red confirmation
        try await Task.sleep(nanoseconds: 100_000_000)
        guard let btn = deleteButton else {
            throw AXError.elementNotFound(description: "Todo confirm-delete button \(todoID)")
        }
        try btn.press()
        try await Task.sleep(nanoseconds: 200_000_000)
        return self
    }

    /// Open the progress popover by hovering/clicking the badge.
    @discardableResult
    public func showProgress() async throws -> TodoRowComponent {
        guard let badge = progressBadge else {
            throw AXError.elementNotFound(description: "Todo progressBadge \(todoID)")
        }
        try badge.press()
        try await Task.sleep(nanoseconds: 200_000_000)
        return self
    }
}
