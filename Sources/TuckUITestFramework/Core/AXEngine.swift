import AppKit
import ApplicationServices

/// Application-level accessibility utilities.
public enum AXEngine {

    /// The system-wide accessibility element (used for global queries).
    public static var systemWide: AXElement {
        AXElement(AXUIElementCreateSystemWide())
    }

    /// Create an `AXElement` for the application with the given PID.
    public static func app(for pid: pid_t) -> AXElement {
        AXElement(AXUIElementCreateApplication(pid))
    }

    /// Create an `AXElement` for the current (host) process.
    public static func currentApp() -> AXElement {
        app(for: ProcessInfo.processInfo.processIdentifier)
    }

    /// Extract the raw application element from any descendant element.
    public static func appElement(for element: AXUIElement) -> AXUIElement {
        var pid: pid_t = 0
        AXUIElementGetPid(element, &pid)
        return AXUIElementCreateApplication(pid)
    }

    /// Configure the messaging timeout for an app-level AX element.
    /// The timeout controls how long the system waits for a response
    /// from the target application.
    public static func configureTimeout(for element: AXElement, seconds: Float) {
        AXUIElementSetMessagingTimeout(element.raw, seconds)
    }

    /// Check whether the current process has accessibility permissions.
    /// This must be granted in System Settings → Privacy → Accessibility.
    public static var hasPermission: Bool {
        AXIsProcessTrusted()
    }

    /// Request accessibility permission if not already granted.
    /// Returns `true` if permission is already granted.
    /// On macOS 14+, this triggers the permission prompt.
    @discardableResult
    public static func requestPermission() -> Bool {
        if AXIsProcessTrusted() { return true }
        return AXIsProcessTrustedWithOptions([
            kAXTrustedCheckOptionPrompt.takeRetainedValue() as String: true
        ] as CFDictionary)
    }

    /// Find a window by title in the current application.
    public static func findWindow(title: String) -> AXElement? {
        let windows = currentApp().children.filter { $0.role == kAXWindowRole }
        return windows.first { $0.title?.contains(title) == true }
    }

    /// Find the first window in the current application.
    public static func firstWindow() -> AXElement? {
        currentApp().children.first { $0.role == kAXWindowRole }
    }

    /// Get all windows for the current application.
    public static func allWindows() -> [AXElement] {
        currentApp().children.filter { $0.role == kAXWindowRole }
    }
}
