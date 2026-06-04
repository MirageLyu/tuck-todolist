import Foundation

enum AgentMode: String {
    case capture
    case edit
    case dailySummary
    case chat
}

@MainActor
final class TodoAgent {
    private let client: ClaudeCLIClient
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init(client: ClaudeCLIClient = ClaudeCLIClient()) {
        self.client = client
        self.encoder = JSONEncoder()
        self.encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        self.encoder.dateEncodingStrategy = .iso8601
        self.decoder = JSONDecoder()
        self.decoder.dateDecodingStrategy = .iso8601
    }

    func run(mode: AgentMode, userText: String, todos: [TodoItem]) async throws -> AgentResponse {
        let prompt = try buildPrompt(mode: mode, userText: userText, todos: todos)
        let output = try await client.complete(prompt: prompt)
        return try decodeResponse(from: output)
    }

    func testClaudeCLIAvailability() async throws {
        try await client.testAvailability()
    }

    private func buildPrompt(mode: AgentMode, userText: String, todos: [TodoItem]) throws -> String {
        let snapshot = AgentRequest(
            mode: mode.rawValue,
            now: ISO8601DateFormatter().string(from: Date()),
            locale: Locale.current.identifier,
            userText: userText,
            todos: todos
        )
        let data = try encoder.encode(snapshot)
        let json = String(data: data, encoding: .utf8) ?? "{}"

        return """
        You are the planning agent inside a native macOS todo-list app.
        Convert the user's natural language into safe structured todo actions.

        Rules:
        - Return JSON only. No markdown fences, no prose outside JSON.
        - Preserve the user's language in titles and replies.
        - Create todos when the user mentions an actionable thing to remember.
        - Use existing todo IDs for update/complete/delete actions.
        - If the user is only chatting, return an empty actions array.
        - For dueDate, use ISO-8601 dates with timezone when you can infer one; otherwise null.
        - priority must be one of: low, normal, high.
        - Never invent deleted or completed items unless the user clearly asked.

        Response schema:
        {
          "reply": "short user-facing response",
          "actions": [
            {
              "type": "createTodo|updateTodo|completeTodo|deleteTodo",
              "todoId": "existing UUID when needed or null",
              "title": "todo title or null",
              "notes": "notes or null",
              "priority": "low|normal|high|null",
              "dueDate": "ISO-8601 date or null",
              "tags": ["tag"] or null
            }
          ],
          "dailySummary": "optional daily plan/summary or null"
        }

        Input:
        \(json)
        """
    }

    private func decodeResponse(from output: String) throws -> AgentResponse {
        let cleaned = stripMarkdownFence(output)
        guard let data = cleaned.data(using: .utf8) else { throw ClaudeCLIError.noOutput }
        return try decoder.decode(AgentResponse.self, from: data)
    }

    private func stripMarkdownFence(_ output: String) -> String {
        var text = output.trimmingCharacters(in: .whitespacesAndNewlines)
        if text.hasPrefix("```") {
            text = text.replacingOccurrences(of: "```json", with: "")
            text = text.replacingOccurrences(of: "```JSON", with: "")
            text = text.replacingOccurrences(of: "```", with: "")
        }
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

private struct AgentRequest: Codable {
    var mode: String
    var now: String
    var locale: String
    var userText: String
    var todos: [TodoItem]
}
