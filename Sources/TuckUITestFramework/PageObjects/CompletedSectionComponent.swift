import AppKit

/// Page object for the Completed section: DisclosureGroup with completed todo rows.
public class CompletedSectionComponent {
    public let root: AXElement

    public init(root: AXElement) {
        self.root = root
    }

    // MARK: - Child Elements

    public var section: AXElement? {
        root.first(identifier: "completed.section")
    }

    // MARK: - Properties

    public var isExpanded: Bool {
        guard let sec = section else { return false }
        // Expanded if children beyond the label are visible
        return sec.children.count > 1
    }

    public var count: Int {
        rows().count
    }

    public var labelText: String? {
        section?.title
    }

    // MARK: - Actions

    @discardableResult
    public func expand() async throws -> CompletedSectionComponent {
        guard let sec = section, !isExpanded else { return self }
        try sec.press()
        try await Task.sleep(nanoseconds: 200_000_000)
        return self
    }

    @discardableResult
    public func collapse() async throws -> CompletedSectionComponent {
        guard let sec = section, isExpanded else { return self }
        try sec.press()
        try await Task.sleep(nanoseconds: 200_000_000)
        return self
    }

    // MARK: - Row Access

    /// Get all completed todo rows (reuses TodoRowComponent).
    public func rows() -> [TodoRowComponent] {
        guard let sec = section else { return [] }
        let prefixes = ["todo.title.", "todo.completeButton.", "todo.deleteButton.", "todo.dueDate.", "todo.progressBadge."]
        var ids = Set<String>()
        for prefix in prefixes {
            for el in sec.descendants(identifierHasPrefix: prefix) {
                guard let identifier = el.identifier else { continue }
                let uuid = String(identifier.dropFirst(prefix.count))
                if !uuid.isEmpty {
                    ids.insert(uuid)
                }
            }
        }
        return ids.compactMap { TodoRowComponent(root: sec, todoID: $0) }
    }
}
