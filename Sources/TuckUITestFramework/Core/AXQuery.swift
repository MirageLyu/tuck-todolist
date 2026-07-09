import Foundation

/// A predicate for matching `AXElement` instances by their accessibility attributes.
/// All non-nil fields must match (AND semantics); nil fields are ignored.
public struct AXPredicate: Sendable {
    public let role: String?
    public let identifier: String?
    public let title: String?
    public let titleContains: String?
    public let subrole: String?

    public init(
        role: String? = nil,
        identifier: String? = nil,
        title: String? = nil,
        titleContains: String? = nil,
        subrole: String? = nil
    ) {
        self.role = role
        self.identifier = identifier
        self.title = title
        self.titleContains = titleContains
        self.subrole = subrole
    }

    /// Returns `true` if `element` matches all non-nil fields of this predicate.
    public func matches(_ element: AXElement) -> Bool {
        if let role, element.role?.caseInsensitiveCompare(role) != .orderedSame { return false }
        if let identifier, element.identifier != identifier { return false }
        if let title, element.title != title { return false }
        if let titleContains, let t = element.title, !t.localizedCaseInsensitiveContains(titleContains) { return false }
        if let subrole, element.subrole?.caseInsensitiveCompare(subrole) != .orderedSame { return false }
        return true
    }

    // MARK: - Factory Methods

    public static var any: AXPredicate { AXPredicate() }

    public static func role(_ r: String) -> AXPredicate {
        AXPredicate(role: r)
    }

    public static func identifier(_ id: String) -> AXPredicate {
        AXPredicate(identifier: id)
    }

    public static func title(_ t: String) -> AXPredicate {
        AXPredicate(title: t)
    }

    public static func titleContains(_ s: String) -> AXPredicate {
        AXPredicate(titleContains: s)
    }
}
