import AppKit

/// Page object for the header area: title, count badge, language button, Claude button.
public class HeaderComponent {
    public let root: AXElement

    public init(root: AXElement) {
        self.root = root
    }

    // MARK: - Child Elements

    private func child(_ id: String) -> AXElement? {
        root.first(identifier: id)
    }

    public var titleElement: AXElement? { child("header.title") }
    public var countBadge: AXElement? { child("header.todoCount") }
    public var languageButton: AXElement? { child("header.languageButton") }
    public var claudeTestButton: AXElement? { child("header.claudeTestButton") }

    // MARK: - Properties

    public var titleText: String? { titleElement?.title }
    public var todoCount: String? { countBadge?.stringValue ?? countBadge?.title }

    public var languageLabel: String? {
        languageButton?.title ?? languageButton?.help
    }

    // MARK: - Actions

    @discardableResult
    public func cycleLanguage() async throws -> HeaderComponent {
        guard let btn = languageButton else {
            throw AXError.elementNotFound(description: "Header languageButton")
        }
        try btn.press()
        try await Task.sleep(nanoseconds: 100_000_000)
        return self
    }

    @discardableResult
    public func clickClaudeTest() async throws -> HeaderComponent {
        guard let btn = claudeTestButton else {
            throw AXError.elementNotFound(description: "Header claudeTestButton")
        }
        try btn.press()
        try await Task.sleep(nanoseconds: 200_000_000)
        return self
    }
}
