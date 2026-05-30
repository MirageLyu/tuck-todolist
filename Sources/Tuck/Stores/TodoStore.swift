import Foundation
import SwiftUI

@MainActor
final class TodoStore: ObservableObject {
    @Published var todos: [TodoItem] = [] {
        didSet { save() }
    }

    @Published var chatMessages: [ChatMessage] = [] {
        didSet { save() }
    }

    @Published var selectedTodoID: UUID?
    @Published var isAgentWorking = false

    private let fileURL: URL
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init() {
        let applicationSupportURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let supportURL = applicationSupportURL.appendingPathComponent("Tuck", isDirectory: true)
        self.fileURL = supportURL.appendingPathComponent("todos.json")

        self.encoder = JSONEncoder()
        self.encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        self.encoder.dateEncodingStrategy = .iso8601

        self.decoder = JSONDecoder()
        self.decoder.dateDecodingStrategy = .iso8601

        migrateLegacyStoreIfNeeded()
        load()
    }

    var completedTodos: [TodoItem] {
        todos.filter { $0.status == .completed }
            .sorted { $0.updatedAt > $1.updatedAt }
    }

    var pendingTodos: [TodoItem] {
        todos.filter { $0.status == .pending }
            .sorted { lhs, rhs in
                switch (lhs.dueDate, rhs.dueDate) {
                case let (left?, right?):
                    if left != right { return left < right }
                case (_?, nil):
                    return true
                case (nil, _?):
                    return false
                case (nil, nil):
                    break
                }
                if lhs.priority != rhs.priority {
                    return priorityRank(lhs.priority) > priorityRank(rhs.priority)
                }
                return lhs.createdAt < rhs.createdAt
            }
    }

    var selectedTodo: TodoItem? {
        guard let selectedTodoID else { return nil }
        return todos.first { $0.id == selectedTodoID }
    }

    func addTodo(title: String, notes: String = "", priority: TodoPriority = .normal, dueDate: Date? = nil, tags: [String] = []) {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return }
        let todo = TodoItem(title: trimmedTitle, notes: notes, priority: priority, dueDate: dueDate, tags: tags)
        todos.append(todo)
        selectedTodoID = todo.id
    }

    func updateTodo(_ todo: TodoItem) {
        guard let index = todos.firstIndex(where: { $0.id == todo.id }) else { return }
        var updated = todo
        updated.updatedAt = Date()
        todos[index] = updated
    }

    func setCompleted(_ todo: TodoItem, completed: Bool) {
        guard let index = todos.firstIndex(where: { $0.id == todo.id }) else { return }
        todos[index].status = completed ? .completed : .pending
        todos[index].updatedAt = Date()
    }

    func addProgress(to todo: TodoItem, content: String) {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let index = todos.firstIndex(where: { $0.id == todo.id }) else { return }
        todos[index].progressEntries.append(TodoProgressEntry(content: trimmed))
        todos[index].updatedAt = Date()
    }

    func updateProgress(todo: TodoItem, entry: TodoProgressEntry, content: String) {
        guard let todoIndex = todos.firstIndex(where: { $0.id == todo.id }),
              let entryIndex = todos[todoIndex].progressEntries.firstIndex(where: { $0.id == entry.id }) else { return }
        todos[todoIndex].progressEntries[entryIndex].content = content
        todos[todoIndex].updatedAt = Date()
    }

    func deleteProgress(todo: TodoItem, entry: TodoProgressEntry) {
        guard let todoIndex = todos.firstIndex(where: { $0.id == todo.id }) else { return }
        todos[todoIndex].progressEntries.removeAll { $0.id == entry.id }
        todos[todoIndex].updatedAt = Date()
    }

    func deleteTodo(_ todo: TodoItem) {
        todos.removeAll { $0.id == todo.id }
        if selectedTodoID == todo.id {
            selectedTodoID = pendingTodos.first?.id ?? completedTodos.first?.id
        }
    }

    func addMessage(role: ChatMessage.Role, text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        chatMessages.append(ChatMessage(role: role, text: trimmed))
    }

    func apply(_ actions: [AgentAction]) {
        for action in actions {
            switch action.type {
            case .createTodo:
                addTodo(
                    title: action.title ?? "Untitled task",
                    notes: action.notes ?? "",
                    priority: action.priority ?? .normal,
                    dueDate: action.dueDate,
                    tags: action.tags ?? []
                )
            case .updateTodo:
                guard let todoId = action.todoId, let index = todos.firstIndex(where: { $0.id == todoId }) else { continue }
                if let title = action.title, !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    todos[index].title = title
                }
                if let notes = action.notes {
                    todos[index].notes = notes
                }
                if let priority = action.priority {
                    todos[index].priority = priority
                }
                if let dueDate = action.dueDate {
                    todos[index].dueDate = dueDate
                }
                if let tags = action.tags {
                    todos[index].tags = tags
                }
                todos[index].updatedAt = Date()
            case .completeTodo:
                guard let todoId = action.todoId, let todo = todos.first(where: { $0.id == todoId }) else { continue }
                setCompleted(todo, completed: true)
            case .deleteTodo:
                guard let todoId = action.todoId, let todo = todos.first(where: { $0.id == todoId }) else { continue }
                deleteTodo(todo)
            }
        }
    }

    private func migrateLegacyStoreIfNeeded() {
        guard !FileManager.default.fileExists(atPath: fileURL.path) else { return }
        let legacyURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("TodoAgent", isDirectory: true)
            .appendingPathComponent("todos.json")
        guard FileManager.default.fileExists(atPath: legacyURL.path) else { return }
        do {
            try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            try FileManager.default.copyItem(at: legacyURL, to: fileURL)
        } catch {
            print("Tuck migration failed: \(error.localizedDescription)")
        }
    }

    private func load() {
        do {
            let data = try Data(contentsOf: fileURL)
            let snapshot = try decoder.decode(StoreSnapshot.self, from: data)
            todos = snapshot.todos
            chatMessages = snapshot.chatMessages
        } catch {
            if loadBackup() { return }
            todos = []
            chatMessages = [ChatMessage(role: .assistant, text: "告诉我你想记录什么，我会帮你整理成 todo。")]
        }
    }

    private func loadBackup() -> Bool {
        let backupURL = fileURL.appendingPathExtension("bak")
        do {
            let data = try Data(contentsOf: backupURL)
            let snapshot = try decoder.decode(StoreSnapshot.self, from: data)
            todos = snapshot.todos
            chatMessages = snapshot.chatMessages
            return true
        } catch {
            return false
        }
    }

    private func save() {
        do {
            try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            if FileManager.default.fileExists(atPath: fileURL.path) {
                let backupURL = fileURL.appendingPathExtension("bak")
                _ = try? FileManager.default.removeItem(at: backupURL)
                try FileManager.default.copyItem(at: fileURL, to: backupURL)
            }
            let snapshot = StoreSnapshot(todos: todos, chatMessages: chatMessages)
            let data = try encoder.encode(snapshot)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            print("Tuck save failed: \(error.localizedDescription)")
        }
    }

    private func priorityRank(_ priority: TodoPriority) -> Int {
        switch priority {
        case .low: 0
        case .normal: 1
        case .high: 2
        }
    }
}

private struct StoreSnapshot: Codable {
    var todos: [TodoItem]
    var chatMessages: [ChatMessage]
}
