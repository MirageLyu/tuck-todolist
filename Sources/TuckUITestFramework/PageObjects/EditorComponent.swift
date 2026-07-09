import AppKit

/// Page object for the editor area: title, notes, priority, due date, progress entries.
public class EditorComponent {
    public let root: AXElement

    public init(root: AXElement) {
        self.root = root
    }

    // MARK: - Child Elements

    private func child(_ id: String) -> AXElement? {
        root.first(identifier: id)
    }

    public var section: AXElement? { child("editor.section") }
    public var titleField: AXElement? { child("editor.titleField") }
    public var notesExpandButton: AXElement? { child("editor.notesExpandButton") }
    public var notesEditor: AXElement? { child("editor.notesEditor") }
    public var notesCollapsed: AXElement? { child("editor.notesCollapsed") }
    public var priorityPicker: AXElement? { child("editor.priorityPicker") }
    public var dueDateToggle: AXElement? { child("editor.dueDateToggle") }
    public var dueDatePicker: AXElement? { child("editor.dueDatePicker") }
    public var progressField: AXElement? { child("editor.progressField") }
    public var progressAddButton: AXElement? { child("editor.progressAddButton") }

    // MARK: - Properties

    public var isExpanded: Bool {
        titleField != nil
    }

    public var titleText: String? {
        titleField?.stringValue
    }

    public var notesText: String? {
        notesEditor?.stringValue
    }

    public var priorityValue: String? {
        priorityPicker?.stringValue ?? priorityPicker?.title
    }

    public var isDueDateEnabled: Bool {
        (dueDateToggle?.numberValue?.intValue ?? 0) == 1
            || dueDatePicker != nil
    }

    public var dueDateDescription: String? {
        dueDatePicker?.stringValue ?? dueDatePicker?.title
    }

    // MARK: - Actions

    @discardableResult
    public func expand() async throws -> EditorComponent {
        // Find the DisclosureGroup triangle or press any editor element to expand
        if let triangle = root.first(matching: AXPredicate(role: kAXDisclosureTriangleRole)) {
            try triangle.press()
        } else if let titleField = titleField {
            try titleField.press()
        }
        try await Task.sleep(nanoseconds: 200_000_000)
        return self
    }

    @discardableResult
    public func collapse() async throws -> EditorComponent {
        if isExpanded {
            try await expand()
        }
        return self
    }

    @discardableResult
    public func setTitle(_ title: String) async throws -> EditorComponent {
        guard let tf = titleField else {
            throw AXError.elementNotFound(description: "Editor titleField")
        }
        try await tf.typeText(title)
        return self
    }

    @discardableResult
    public func expandNotes() async throws -> EditorComponent {
        guard let btn = notesExpandButton else {
            throw AXError.elementNotFound(description: "Editor notesExpandButton")
        }
        try btn.press()
        try await Task.sleep(nanoseconds: 200_000_000)
        return self
    }

    @discardableResult
    public func collapseNotes() async throws -> EditorComponent {
        guard let btn = notesCollapsed else { return self }
        try btn.press()
        try await Task.sleep(nanoseconds: 100_000_000)
        return self
    }

    @discardableResult
    public func setNotes(_ notes: String) async throws -> EditorComponent {
        if notesEditor == nil { try await expandNotes() }
        guard let editor = notesEditor else {
            throw AXError.elementNotFound(description: "Editor notesEditor")
        }
        try await editor.typeText(notes)
        return self
    }

    @discardableResult
    public func selectPriority(_ priority: String) async throws -> EditorComponent {
        guard let picker = priorityPicker else {
            throw AXError.elementNotFound(description: "Editor priorityPicker")
        }
        try await picker.pick(priority)
        return self
    }

    @discardableResult
    public func toggleDueDate() async throws -> EditorComponent {
        guard let toggle = dueDateToggle else {
            throw AXError.elementNotFound(description: "Editor dueDateToggle")
        }
        try toggle.press()
        try await Task.sleep(nanoseconds: 200_000_000)
        return self
    }

    @discardableResult
    public func setDueDate(_ daysFromNow: Int) async throws -> EditorComponent {
        if !isDueDateEnabled { try await toggleDueDate() }
        guard let picker = dueDatePicker else {
            throw AXError.elementNotFound(description: "Editor dueDatePicker")
        }
        // The DatePicker is a complex control; we can press it to open a calendar
        try picker.press()
        try await Task.sleep(nanoseconds: 300_000_000)
        // After this, a calendar popover would appear — platform-specific interaction
        return self
    }

    @discardableResult
    public func addProgress(_ content: String) async throws -> EditorComponent {
        guard let tf = progressField else {
            throw AXError.elementNotFound(description: "Editor progressField")
        }
        try await tf.typeText(content)
        guard let btn = progressAddButton else {
            throw AXError.elementNotFound(description: "Editor progressAddButton")
        }
        try btn.press()
        try await Task.sleep(nanoseconds: 200_000_000)
        return self
    }

    /// Get all progress entry text contents currently visible.
    public func progressEntries() -> [String] {
        guard let section = root.first(identifier: "editor.progressList") else { return [] }
        return section.children.compactMap { child in
            child.stringValue ?? child.title
        }
    }

    /// Wait for the editor to become expanded with content.
    @discardableResult
    public func waitForExpanded(timeout: TimeInterval = 5) async throws -> EditorComponent {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if isExpanded { return self }
            try await Task.sleep(nanoseconds: 200_000_000)
        }
        throw AXError.timeout(description: "Editor expanded")
    }
}
