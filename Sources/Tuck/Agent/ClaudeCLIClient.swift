import Foundation
import Darwin

enum ClaudeCLIError: LocalizedError {
    case executableNotFound([String])
    case timedOut
    case failed(String)
    case noOutput
    case unexpectedAvailabilityResponse(String)

    var errorDescription: String? {
        switch self {
        case let .executableNotFound(paths):
            "找不到 claude 命令。请先安装并登录 Claude Code CLI。已检查：\(paths.joined(separator: ", "))"
        case .timedOut:
            "Claude CLI 响应超时。"
        case let .failed(message):
            message
        case .noOutput:
            "Claude CLI 没有返回内容。"
        case let .unexpectedAvailabilityResponse(output):
            "Claude CLI 返回了非预期内容：\(output)"
        }
    }
}

private final class ContinuationResumer<T: Sendable>: @unchecked Sendable {
    private let lock = NSLock()
    private var continuation: CheckedContinuation<T, Error>?

    init(continuation: CheckedContinuation<T, Error>) {
        self.continuation = continuation
    }

    func resume(_ result: Result<T, Error>) {
        lock.lock()
        guard let continuation else {
            lock.unlock()
            return
        }
        self.continuation = nil
        lock.unlock()
        continuation.resume(with: result)
    }
}

private final class PipeCollector: @unchecked Sendable {
    let pipe = Pipe()
    private let lock = NSLock()
    private var data = Data()

    init() {
        pipe.fileHandleForReading.readabilityHandler = { [weak self] handle in
            let chunk = handle.availableData
            guard !chunk.isEmpty else { return }
            self?.append(chunk)
        }
    }

    func finish() -> String {
        pipe.fileHandleForReading.readabilityHandler = nil
        append(pipe.fileHandleForReading.readDataToEndOfFile())
        lock.lock()
        let data = self.data
        lock.unlock()
        return String(data: data, encoding: .utf8) ?? ""
    }

    private func append(_ chunk: Data) {
        guard !chunk.isEmpty else { return }
        lock.lock()
        data.append(chunk)
        lock.unlock()
    }
}

final class ClaudeCLIClient {
    private let timeout: TimeInterval

    init(timeout: TimeInterval = 45) {
        self.timeout = timeout
    }

    func complete(prompt: String) async throws -> String {
        let executable = try findClaudeExecutable()
        return try await runClaude(executable: executable, arguments: [
            "--print",
            "--output-format", "text",
            "--no-session-persistence",
            prompt
        ], requiresOutput: true)
    }

    func testAvailability() async throws {
        let executable = try findClaudeExecutable()
        let output = try await runClaude(executable: executable, arguments: [
            "--print",
            "--output-format", "text",
            "--no-session-persistence",
            "Reply with exactly: ok"
        ], requiresOutput: true)
        guard ClaudeCLIClient.isExpectedAvailabilityResponse(output) else {
            throw ClaudeCLIError.unexpectedAvailabilityResponse(ClaudeCLIClient.displaySnippet(output))
        }
    }

    private func runClaude(executable: URL, arguments: [String], requiresOutput: Bool) async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            let process = Process()
            process.executableURL = executable
            process.arguments = arguments

            let outputCollector = PipeCollector()
            let errorCollector = PipeCollector()
            process.standardOutput = outputCollector.pipe
            process.standardError = errorCollector.pipe

            let resumer = ContinuationResumer(continuation: continuation)

            process.terminationHandler = { finishedProcess in
                let output = outputCollector.finish()
                let stderr = errorCollector.finish()
                if finishedProcess.terminationStatus == 0 {
                    let trimmed = output.trimmingCharacters(in: .whitespacesAndNewlines)
                    requiresOutput && trimmed.isEmpty ? resumer.resume(.failure(ClaudeCLIError.noOutput)) : resumer.resume(.success(trimmed))
                } else {
                    let message = stderr.trimmingCharacters(in: .whitespacesAndNewlines)
                    resumer.resume(.failure(ClaudeCLIError.failed(message.isEmpty ? "Claude CLI exited with status \(finishedProcess.terminationStatus)." : message)))
                }
            }

            do {
                try process.run()
            } catch {
                resumer.resume(.failure(error))
                return
            }

            DispatchQueue.global().asyncAfter(deadline: .now() + timeout) {
                guard process.isRunning else { return }
                process.terminate()
                DispatchQueue.global().asyncAfter(deadline: .now() + 1) {
                    guard process.isRunning else { return }
                    kill(process.processIdentifier, SIGKILL)
                }
                resumer.resume(.failure(ClaudeCLIError.timedOut))
            }
        }
    }

    static func isExpectedAvailabilityResponse(_ output: String) -> Bool {
        output
            .split(whereSeparator: \.isNewline)
            .contains { line in
                let normalized = line.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                return normalized == "ok" || normalized == "ok."
            }
    }

    static func displaySnippet(_ output: String, limit: Int = 400) -> String {
        let trimmed = output.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count > limit else { return trimmed }
        let end = trimmed.index(trimmed.startIndex, offsetBy: limit)
        return String(trimmed[..<end]) + "…"
    }

    private func findClaudeExecutable() throws -> URL {
        let homeDirectory = FileManager.default.homeDirectoryForCurrentUser.path
        let candidates = [
            "\(homeDirectory)/.local/bin/claude",
            "\(homeDirectory)/bin/claude",
            "/opt/homebrew/bin/claude",
            "/usr/local/bin/claude",
            "/usr/bin/claude"
        ]

        for candidate in candidates where FileManager.default.isExecutableFile(atPath: candidate) {
            return URL(fileURLWithPath: candidate)
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = ["which", "claude"]
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe()
        try? process.run()
        process.waitUntilExit()

        guard process.terminationStatus == 0 else { throw ClaudeCLIError.executableNotFound(candidates) }
        let path = String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !path.isEmpty, FileManager.default.isExecutableFile(atPath: path) else {
            throw ClaudeCLIError.executableNotFound(candidates)
        }
        return URL(fileURLWithPath: path)
    }
}
