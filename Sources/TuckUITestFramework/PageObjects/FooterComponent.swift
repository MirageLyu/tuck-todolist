import AppKit

/// Page object for the footer area: summary text and quit button.
public class FooterComponent {
    public let root: AXElement

    public init(root: AXElement) {
        self.root = root
    }

    // MARK: - Child Elements

    public var summaryText: AXElement? {
        root.first(identifier: "footer.summary")
    }

    public var quitButton: AXElement? {
        root.first(identifier: "footer.quitButton")
    }

    // MARK: - Properties

    public var summary: String? {
        summaryText?.title ?? summaryText?.stringValue
    }

    public var isQuitButtonEnabled: Bool {
        quitButton?.isEnabled ?? false
    }

    // MARK: - Actions

    @discardableResult
    public func quit() async throws -> FooterComponent {
        guard let btn = quitButton else {
            throw AXError.elementNotFound(description: "Footer quitButton")
        }
        try btn.press()
        return self
    }
}
