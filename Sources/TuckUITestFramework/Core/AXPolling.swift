import Foundation

extension AXElement {

    /// Poll until a descendant matching `predicate` is found or `timeout` is reached.
    @discardableResult
    public func waitFor(
        _ predicate: AXPredicate,
        timeout: TimeInterval = 5.0,
        interval: TimeInterval = 0.2
    ) async throws -> AXElement {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if let found = first(matching: predicate) {
                return found
            }
            try await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
        }
        throw AXError.timeout(description: "waitFor(\(predicate)) in \(self)")
    }

    /// Poll until a descendant with the given accessibility identifier is found.
    @discardableResult
    public func waitFor(
        identifier: String,
        timeout: TimeInterval = 5.0,
        interval: TimeInterval = 0.2
    ) async throws -> AXElement {
        try await waitFor(AXPredicate(identifier: identifier), timeout: timeout, interval: interval)
    }

    /// Poll until a descendant with the given role and title is found.
    @discardableResult
    public func waitFor(
        role: String,
        title: String,
        timeout: TimeInterval = 5.0,
        interval: TimeInterval = 0.2
    ) async throws -> AXElement {
        try await waitFor(AXPredicate(role: role, title: title), timeout: timeout, interval: interval)
    }

    /// Poll until a descendant with text content containing `text` is found.
    @discardableResult
    public func waitFor(
        text: String,
        timeout: TimeInterval = 5.0,
        interval: TimeInterval = 0.2
    ) async throws -> AXElement {
        try await waitFor(AXPredicate(titleContains: text), timeout: timeout, interval: interval)
    }

    /// Poll until this element's `isEnabled` property is `true`.
    @discardableResult
    public func waitForEnabled(timeout: TimeInterval = 5.0, interval: TimeInterval = 0.2) async throws -> AXElement {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if isEnabled { return self }
            try await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
        }
        throw AXError.timeout(description: "waitForEnabled: \(self)")
    }
}
