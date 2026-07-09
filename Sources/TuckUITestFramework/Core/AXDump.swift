import AppKit

extension AXElement {

    /// Recursively print the accessibility tree starting from this element.
    /// Useful for debugging test failures.
    public func dump(label: String = "AX Tree", maxDepth: Int = 5) {
        print("=== \(label) ===")
        _dump(depth: 0, maxDepth: maxDepth)
        print(String(repeating: "=", count: 40))
    }

    private func _dump(depth: Int, maxDepth: Int) {
        guard depth <= maxDepth else { return }
        let indent = String(repeating: "  ", count: depth)

        let r = role ?? "nil"
        let t = title.map { "\"\($0)\"" } ?? "nil"
        let id = identifier.map { "#\($0)" } ?? ""
        let val = stringValue.map { "= \($0)" } ?? ""
        let info = [r, t, id, val].filter { !$0.isEmpty && $0 != "nil" }.joined(separator: " ")

        print("\(indent)[\(r)] \(info)")

        for child in children {
            child._dump(depth: depth + 1, maxDepth: maxDepth)
        }
    }

    /// Return a compact string description of the tree.
    public func treeDescription(maxDepth: Int = 5) -> String {
        var lines: [String] = []
        _collect(lines: &lines, depth: 0, maxDepth: maxDepth)
        return lines.joined(separator: "\n")
    }

    private func _collect(lines: inout [String], depth: Int, maxDepth: Int) {
        guard depth <= maxDepth else { return }
        let indent = String(repeating: "  ", count: depth)
        let r = role ?? "nil"
        let id = identifier.map { " #\($0)" } ?? ""
        let t = title.map { " \"\($0)\"" } ?? ""
        lines.append("\(indent)[\(r)]\(id)\(t)")

        for child in children {
            child._collect(lines: &lines, depth: depth + 1, maxDepth: maxDepth)
        }
    }
}
