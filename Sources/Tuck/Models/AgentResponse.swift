import Foundation

struct AgentResponse: Codable {
    var reply: String
    var actions: [AgentAction]
    var dailySummary: String?
}

struct AgentAction: Codable, Identifiable {
    enum ActionType: String, Codable {
        case createTodo
        case updateTodo
        case completeTodo
        case deleteTodo
    }

    var id = UUID()
    var type: ActionType
    var todoId: UUID?
    var title: String?
    var notes: String?
    var priority: TodoPriority?
    var dueDate: Date?
    var tags: [String]?

    enum CodingKeys: String, CodingKey {
        case type
        case todoId
        case title
        case notes
        case priority
        case dueDate
        case tags
    }
}
