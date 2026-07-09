import Foundation
import XCTest

// MARK: - Element Assertions

extension AXElement {

    /// Fluent assertion builder. Throws `AXAssertionError` on failure.
    /// Returns `self` for chaining.
    @discardableResult
    public func should(
        _ matcher: AXMatcher,
        file: StaticString = #file,
        line: UInt = #line
    ) async throws -> Self {
        let result = evaluate(matcher)
        if case .failure(let message) = result {
            throw AXAssertionError(description: message, file: file, line: line)
        }
        return self
    }

    private func evaluate(_ matcher: AXMatcher) -> AXMatchResult {
        switch matcher {
        case .exist:
            return role != nil ? .success : .failure("expected element to exist, but role is nil")

        case .notExist:
            return role == nil ? .success : .failure("expected element to not exist, but found role=\(role!)")

        case .haveRole(let expected):
            let actual = role ?? "nil"
            return actual.caseInsensitiveCompare(expected) == .orderedSame
                ? .success
                : .failure("expected role '\(expected)', got '\(actual)'")

        case .haveTitle(let expected):
            let actual = title ?? "nil"
            return actual == expected
                ? .success
                : .failure("expected title '\(expected)', got '\(actual)'")

        case .haveIdentifier(let expected):
            let actual = identifier ?? "nil"
            return actual == expected
                ? .success
                : .failure("expected identifier '\(expected)', got '\(actual)'")

        case .beEnabled:
            return isEnabled
                ? .success
                : .failure("expected element to be enabled, but it is disabled")

        case .beDisabled:
            return !isEnabled
                ? .success
                : .failure("expected element to be disabled, but it is enabled")

        case .beFocused:
            return isFocused
                ? .success
                : .failure("expected element to be focused, but it is not")

        case .containText(let text):
            let sv = stringValue ?? title ?? ""
            return sv.localizedCaseInsensitiveContains(text)
                ? .success
                : .failure("expected text to contain '\(text)', got '\(sv)'")

        case .haveChildCount(let expected):
            let count = children.count
            return count == expected
                ? .success
                : .failure("expected \(expected) children, got \(count)")
        }
    }
}

// MARK: - Collection Assertions

extension Array where Element == AXElement {

    @discardableResult
    public func should(
        _ matcher: CollectionMatcher,
        file: StaticString = #file,
        line: UInt = #line
    ) async throws -> Self {
        let result = evaluate(matcher)
        if case .failure(let message) = result {
            throw AXAssertionError(description: message, file: file, line: line)
        }
        return self
    }

    private func evaluate(_ matcher: CollectionMatcher) -> AXMatchResult {
        switch matcher {
        case .haveCount(let expected):
            return count == expected
                ? .success
                : .failure("expected \(expected) elements, got \(count)")

        case .beEmpty:
            return isEmpty
                ? .success
                : .failure("expected empty collection, got \(count) elements")

        case .notBeEmpty:
            return !isEmpty
                ? .success
                : .failure("expected non-empty collection, but it is empty")
        }
    }
}

// MARK: - XCAssert Wrappers (synchronous, for XCTest integration)

extension AXElement {

    /// Synchronous wrapper for `should(.exist)` — asserts in XCTest.
    public func assertExists(
        _ message: String? = nil,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        XCTAssertNotNil(role, message ?? "expected element to exist", file: file, line: line)
    }

    /// Synchronous wrapper for `should(.haveIdentifier)`.
    public func assertIdentifier(
        _ expected: String,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        XCTAssertEqual(identifier, expected, "identifier mismatch", file: file, line: line)
    }

    /// Synchronous wrapper for `should(.haveRole)`.
    public func assertRole(
        _ expected: String,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        XCTAssertEqual(role?.lowercased(), expected.lowercased(), "role mismatch", file: file, line: line)
    }

    /// Synchronous wrapper for `should(.containText)`.
    public func assertContainsText(
        _ text: String,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let sv = stringValue ?? title ?? ""
        XCTAssertTrue(
            sv.localizedCaseInsensitiveContains(text),
            "expected '\(sv)' to contain '\(text)'",
            file: file,
            line: line
        )
    }
}

// MARK: - Matcher Types

public enum AXMatcher {
    case exist
    case notExist
    case haveRole(String)
    case haveTitle(String)
    case haveIdentifier(String)
    case beEnabled
    case beDisabled
    case beFocused
    case containText(String)
    case haveChildCount(Int)
}

public enum CollectionMatcher {
    case haveCount(Int)
    case beEmpty
    case notBeEmpty
}

private enum AXMatchResult {
    case success
    case failure(String)
}

// MARK: - Assertion Error

public struct AXAssertionError: Swift.Error, CustomStringConvertible {
    public let description: String
    public let file: StaticString
    public let line: UInt

    public init(description: String, file: StaticString = #file, line: UInt = #line) {
        self.description = description
        self.file = file
        self.line = line
    }
}
