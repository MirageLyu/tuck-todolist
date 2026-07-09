import AppKit

/// Page object for the Quick Capture area: text field, capture button, status text.
public class QuickCaptureComponent {
    public let root: AXElement

    public init(root: AXElement) {
        self.root = root
    }

    // MARK: - Child Elements

    private func child(_ id: String) -> AXElement? {
        root.first(identifier: id)
    }

    public var textField: AXElement? { child("quickCapture.textField") }
    public var captureButton: AXElement? { child("quickCapture.captureButton") }
    public var statusText: AXElement? { child("quickCapture.statusText") }

    // MARK: - Properties

    public var currentText: String? {
        textField?.stringValue
    }

    public var captureButtonTitle: String? {
        captureButton?.title
    }

    public var isCaptureEnabled: Bool {
        captureButton?.isEnabled ?? false
    }

    public var statusMessage: String? {
        statusText?.stringValue ?? statusText?.title
    }

    public var isTextFieldFocused: Bool {
        textField?.isFocused ?? false
    }

    // MARK: - Actions

    @discardableResult
    public func enterText(_ text: String) async throws -> QuickCaptureComponent {
        guard let tf = textField else {
            throw AXError.elementNotFound(description: "QuickCapture textField")
        }
        try await tf.typeText(text)
        return self
    }

    @discardableResult
    public func clearAndEnterText(_ text: String) async throws -> QuickCaptureComponent {
        try await enterText(text)
        return self
    }

    @discardableResult
    public func capture() async throws -> QuickCaptureComponent {
        guard let btn = captureButton else {
            throw AXError.elementNotFound(description: "QuickCapture captureButton")
        }
        try btn.press()
        try await Task.sleep(nanoseconds: 300_000_000)
        return self
    }

    @discardableResult
    public func capture(_ text: String) async throws -> QuickCaptureComponent {
        try await enterText(text)
        // Wait for SwiftUI binding to update after paste
        try await Task.sleep(nanoseconds: 300_000_000)
        try await capture()
        return self
    }

    @discardableResult
    public func waitForStatus(containing text: String, timeout: TimeInterval = 5) async throws -> QuickCaptureComponent {
        _ = try await root.waitFor(text: text, timeout: timeout)
        return self
    }
}
