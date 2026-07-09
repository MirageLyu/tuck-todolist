import AppKit

/// Top-level window-level page object that aggregates all UI component page objects.
public class MenuBarWindow {
    public let windowElement: AXElement

    public init(windowElement: AXElement) {
        self.windowElement = windowElement
    }

    // MARK: - Components (lazily resolved)

    public private(set) lazy var header = HeaderComponent(root: windowElement)
    public private(set) lazy var quickCapture = QuickCaptureComponent(root: windowElement)
    public private(set) lazy var todoList = TodoListComponent(root: windowElement)
    public private(set) lazy var editor = EditorComponent(root: windowElement)
    public private(set) lazy var completedSection = CompletedSectionComponent(root: windowElement)
    public private(set) lazy var footer = FooterComponent(root: windowElement)

    // MARK: - Window-level

    public var title: String? {
        windowElement.title
    }

    public var size: CGSize? {
        windowElement.size
    }

    /// Dump the entire accessibility tree of the window.
    public func dumpTree(label: String = "MenuBarWindow", maxDepth: Int = 5) {
        windowElement.dump(label: label, maxDepth: maxDepth)
    }

    /// Wait for the window to be fully accessible (key elements present).
    @discardableResult
    public func waitForReady(timeout: TimeInterval = 5) async throws -> MenuBarWindow {
        _ = try await windowElement.waitFor(identifier: "quickCapture.textField", timeout: timeout)
        return self
    }

    /// Refresh all lazy components by re-resolving from the window element.
    public func refresh() {
        header = HeaderComponent(root: windowElement)
        quickCapture = QuickCaptureComponent(root: windowElement)
        todoList = TodoListComponent(root: windowElement)
        editor = EditorComponent(root: windowElement)
        completedSection = CompletedSectionComponent(root: windowElement)
        footer = FooterComponent(root: windowElement)
    }
}
