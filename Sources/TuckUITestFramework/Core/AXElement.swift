import AppKit
@preconcurrency import ApplicationServices

// MARK: - AXError

/// Errors thrown by AXElement operations.
public enum AXError: Swift.Error, CustomStringConvertible {
    case actionFailed(action: String, code: Int32)
    case timeout(description: String)
    case elementNotFound(description: String)

    public var description: String {
        switch self {
        case .actionFailed(let action, let code):
            return "AX action '\(action)' failed with AXError code \(code)"
        case .timeout(let desc):
            return "Timeout waiting for: \(desc)"
        case .elementNotFound(let desc):
            return "Element not found: \(desc)"
        }
    }
}

/// A value-type wrapper around `AXUIElement` providing ergonomic access to
/// the macOS Accessibility API for UI testing.
public struct AXElement: Sendable {
    public let raw: AXUIElement

    public init(_ raw: AXUIElement) {
        self.raw = raw
    }

    // MARK: - Attribute Helpers

    private func attribute<T>(_ key: String, as type: T.Type = T.self) -> T? {
        var value: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(raw, key as CFString, &value)
        guard result == .success, let v = value else { return nil }
        return v as? T
    }

    private func stringAttribute(_ key: String) -> String? {
        attribute(key, as: String.self)
    }

    private func boolAttribute(_ key: String) -> Bool {
        attribute(key, as: NSNumber.self)?.boolValue ?? false
    }

    // MARK: - Core Properties

    public var role: String? { stringAttribute(kAXRoleAttribute) }
    public var subrole: String? { stringAttribute(kAXSubroleAttribute) }
    public var title: String? { stringAttribute(kAXTitleAttribute) }
    public var identifier: String? { stringAttribute(kAXIdentifierAttribute) }
    public var help: String? { stringAttribute(kAXHelpAttribute) }

    /// Best-effort value extraction. Tries String, then NSNumber.
    public var value: Any? {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(raw, kAXValueAttribute as CFString, &value) == .success,
              let v = value else { return nil }
        return v
    }

    public var stringValue: String? {
        if let s = value as? String { return s }
        if let n = value as? NSNumber { return n.stringValue }
        return nil
    }

    public var numberValue: NSNumber? {
        value as? NSNumber
    }

    public var isEnabled: Bool { boolAttribute(kAXEnabledAttribute) }
    public var isFocused: Bool { boolAttribute(kAXFocusedAttribute) }

    public var position: CGPoint? {
        guard let v = attribute(kAXPositionAttribute, as: AXValue.self) else { return nil }
        var point = CGPoint.zero
        guard AXValueGetValue(v, .cgPoint, &point) else { return nil }
        return point
    }

    public var size: CGSize? {
        guard let v = attribute(kAXSizeAttribute, as: AXValue.self) else { return nil }
        var size = CGSize.zero
        guard AXValueGetValue(v, .cgSize, &size) else { return nil }
        return size
    }

    public var frame: CGRect? {
        guard let pos = position, let sz = size else { return nil }
        return CGRect(origin: pos, size: sz)
    }

    // MARK: - Hierarchy

    public var children: [AXElement] {
        guard let cfArray = attribute(kAXChildrenAttribute, as: CFArray.self) else { return [] }
        return (cfArray as [AnyObject]).compactMap { obj in
            AXElement(obj as! AXUIElement)
        }
    }

    public var parent: AXElement? {
        guard let el = attribute(kAXParentAttribute, as: AXUIElement.self) else { return nil }
        return AXElement(el)
    }

    /// Walk up to find the nearest window.
    public var nearestWindow: AXElement? {
        var el: AXElement = self
        while let p = el.parent {
            if p.role == kAXWindowRole { return p }
            el = p
        }
        return nil
    }

    // MARK: - Query

    /// All descendants (recursive) matching the given predicate.
    public func descendants(matching predicate: AXPredicate) -> [AXElement] {
        var results: [AXElement] = []
        for child in children {
            if predicate.matches(child) { results.append(child) }
            results.append(contentsOf: child.descendants(matching: predicate))
        }
        return results
    }

    /// First descendant matching the predicate, depth-first.
    public func first(matching predicate: AXPredicate) -> AXElement? {
        for child in children {
            if predicate.matches(child) { return child }
            if let found = child.first(matching: predicate) { return found }
        }
        return nil
    }

    /// First descendant with the given role.
    public func first(role: String) -> AXElement? {
        first(matching: AXPredicate(role: role))
    }

    /// First descendant with the given accessibility identifier.
    public func first(identifier: String) -> AXElement? {
        first(matching: AXPredicate(identifier: identifier))
    }

    /// Whether this element's subtree contains a match.
    public func contains(_ predicate: AXPredicate) -> Bool {
        first(matching: predicate) != nil
    }

    /// All descendants with the given role.
    public func all(role: String) -> [AXElement] {
        descendants(matching: AXPredicate(role: role))
    }

    /// All descendants whose identifier starts with the given prefix.
    public func descendants(identifierHasPrefix prefix: String) -> [AXElement] {
        var results: [AXElement] = []
        for child in children {
            if let id = child.identifier, id.hasPrefix(prefix) {
                results.append(child)
            }
            results.append(contentsOf: child.descendants(identifierHasPrefix: prefix))
        }
        return results
    }

    // MARK: - Actions

    @discardableResult
    private func performAction(_ action: String) throws -> AXError? {
        let result = AXUIElementPerformAction(raw, action as CFString)
        guard result == .success else {
            throw AXError.actionFailed(action: action, code: result.rawValue)
        }
        return nil
    }

    public func press() throws {
        try performAction(kAXPressAction)
    }

    public func confirm() throws {
        let result = AXUIElementPerformAction(raw, kAXConfirmAction as CFString)
        if result == .success { return }
        try performAction(kAXPressAction)
    }

    public func click() throws {
        try press()
    }

    @discardableResult
    public func setValue(_ newValue: Any) throws -> AXError? {
        let result = AXUIElementSetAttributeValue(raw, kAXValueAttribute as CFString, newValue as CFTypeRef)
        guard result == .success else {
            throw AXError.actionFailed(action: "setValue", code: result.rawValue)
        }
        return nil
    }

    // MARK: - Async Actions (with yield for SwiftUI updates)

    /// Type text into a text field using clipboard paste (Cmd+A, Cmd+V).
    /// This is more reliable than setting AXValue which doesn't update SwiftUI bindings.
    /// Uses CGEventPostToPid to target only the specific app process,
    /// so it won't steal keyboard focus from the user's foreground app.
    /// After typing, yields to the runloop so SwiftUI can process the binding.
    public func typeText(_ text: String) async throws {
        let targetPID = self.pid

        // Save current frontmost app to restore later
        let frontmostApp = NSWorkspace.shared.frontmostApplication

        // First focus the element
        AXUIElementSetAttributeValue(raw, kAXFocusedAttribute as CFString, kCFBooleanTrue!)
        try await Task.sleep(nanoseconds: 50_000_000)

        // Use clipboard + paste for reliable text input with SwiftUI bindings
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)

        // Simulate Cmd+A (select all) then Cmd+V (paste)
        let source = CGEventSource(stateID: .hidSystemState)

        // Cmd+A — sent directly to target process
        if let cmdA_down = CGEvent(keyboardEventSource: source, virtualKey: 0x00, keyDown: true),
           let cmdA_up = CGEvent(keyboardEventSource: source, virtualKey: 0x00, keyDown: false) {
            cmdA_down.flags = .maskCommand
            cmdA_up.flags = .maskCommand
            cmdA_down.postToPid(targetPID)
            cmdA_up.postToPid(targetPID)
        }
        try await Task.sleep(nanoseconds: 100_000_000)

        // Cmd+V — sent directly to target process
        if let cmdV_down = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: true),
           let cmdV_up = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: false) {
            cmdV_down.flags = .maskCommand
            cmdV_up.flags = .maskCommand
            cmdV_down.postToPid(targetPID)
            cmdV_up.postToPid(targetPID)
        }

        try await Task.sleep(nanoseconds: 100_000_000)

        // Restore the user's previous foreground app
        if let prev = frontmostApp {
            prev.activate()
        }
    }

    /// Clear the text field and type new text.
    public func clearAndType(_ text: String) async throws {
        try await typeText(text)
    }

    /// Show the contextual menu and pick an item by title.
    public func pick(_ value: String) async throws {
        try performAction(kAXShowMenuAction)
        try await Task.sleep(nanoseconds: 150_000_000)

        // Search for the menu that appeared
        let app = AXElement(AXUIElementCreateApplication(pid))
        let menuItem = app.first(matching: AXPredicate(role: kAXMenuItemRole, title: value))
            ?? app.first(matching: AXPredicate(role: kAXStaticTextRole, title: value))

        if let item = menuItem {
            try item.press()
        } else {
            throw AXError.elementNotFound(description: "Menu item '\(value)'")
        }
    }

    // MARK: - PID

    public var pid: pid_t {
        var pid: pid_t = 0
        AXUIElementGetPid(raw, &pid)
        return pid
    }

    /// Wait for this element to appear in the accessibility tree.
    @discardableResult
    public func waitForExistence(timeout: TimeInterval = 5.0, interval: TimeInterval = 0.2) async throws -> AXElement {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if role != nil { return self }
            try await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
        }
        throw AXError.timeout(description: "Element existence: \(self)")
    }
}

// MARK: - Equatable

extension AXElement: Equatable {
    public static func == (lhs: AXElement, rhs: AXElement) -> Bool {
        CFEqual(lhs.raw, rhs.raw)
    }
}

// MARK: - Hashable

extension AXElement: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(CFHash(raw))
    }
}

// MARK: - CustomStringConvertible

extension AXElement: CustomStringConvertible {
    public var description: String {
        let r = role ?? "nil"
        let t = title ?? "nil"
        let id = identifier ?? "nil"
        return "AXElement(role: \(r), title: \(t), id: \(id))"
    }
}
