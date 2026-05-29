import Foundation

enum TodoStatus: String, Codable, CaseIterable, Identifiable {
    case pending
    case completed

    var id: String { rawValue }
}

enum TodoPriority: String, Codable, CaseIterable, Identifiable {
    case low
    case normal
    case high

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .low: "Low"
        case .normal: "Normal"
        case .high: "High"
        }
    }
}

struct TodoItem: Identifiable, Codable, Hashable {
    var id: UUID
    var title: String
    var notes: String
    var status: TodoStatus
    var priority: TodoPriority
    var dueDate: Date?
    var tags: [String]
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        title: String,
        notes: String = "",
        status: TodoStatus = .pending,
        priority: TodoPriority = .normal,
        dueDate: Date? = nil,
        tags: [String] = [],
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.notes = notes
        self.status = status
        self.priority = priority
        self.dueDate = dueDate
        self.tags = tags
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

struct ChatMessage: Identifiable, Codable, Hashable {
    enum Role: String, Codable {
        case user
        case assistant
        case system
    }

    var id: UUID
    var role: Role
    var text: String
    var createdAt: Date

    init(id: UUID = UUID(), role: Role, text: String, createdAt: Date = Date()) {
        self.id = id
        self.role = role
        self.text = text
        self.createdAt = createdAt
    }
}
