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

struct TodoProgressEntry: Identifiable, Codable, Hashable {
    var id: UUID
    var content: String
    var createdAt: Date

    init(id: UUID = UUID(), content: String, createdAt: Date = Date()) {
        self.id = id
        self.content = content
        self.createdAt = createdAt
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
    var progressEntries: [TodoProgressEntry]
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
        progressEntries: [TodoProgressEntry] = [],
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
        self.progressEntries = progressEntries
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case notes
        case status
        case priority
        case dueDate
        case tags
        case progressEntries
        case createdAt
        case updatedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.title = try container.decode(String.self, forKey: .title)
        self.notes = try container.decodeIfPresent(String.self, forKey: .notes) ?? ""
        self.status = try container.decodeIfPresent(TodoStatus.self, forKey: .status) ?? .pending
        self.priority = try container.decodeIfPresent(TodoPriority.self, forKey: .priority) ?? .normal
        self.dueDate = try container.decodeIfPresent(Date.self, forKey: .dueDate)
        self.tags = try container.decodeIfPresent([String].self, forKey: .tags) ?? []
        self.progressEntries = try container.decodeIfPresent([TodoProgressEntry].self, forKey: .progressEntries) ?? []
        self.createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
        self.updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt) ?? self.createdAt
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
