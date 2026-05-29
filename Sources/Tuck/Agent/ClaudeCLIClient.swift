import Foundation

enum ClaudeCLIError: LocalizedError {
    case executableNotFound
    case timedOut
    case failed(String)
    case noOutput

    var errorDescription: String? {
        switch self {
        case .executableNotFound:
            "找不到 claude 命令。请先安装并登录 Claude Code CLI。"
        case .timedOut:
            "Claude CLI 响应超时。"
        case let .failed(message):
            message
        case .noOutput:
            "Claude CLI 没有返回内容。"
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

final class ClaudeCLIClient {
    private let timeout: TimeInterval

    init(timeout: TimeInterval = 45) {
        self.timeout = timeout
    }

    func complete(prompt: String) async throws -> String {
        let executable = try findClaudeExecutable()
        return try await withCheckedThrowingContinuation { continuation in
            let process = Process()
            process.executableURL = executable
            process.arguments = [
                "--print",
                "--output-format", "text",
                "--no-session-persistence",
                prompt
            ]

            let outputPipe = Pipe()
            let errorPipe = Pipe()
            process.standardOutput = outputPipe
            process.standardError = errorPipe

            let resumer = ContinuationResumer(continuation: continuation)

            process.terminationHandler = { finishedProcess in
                let output = String(data: outputPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
                let stderr = String(data: errorPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
                if finishedProcess.terminationStatus == 0 {
                    let trimmed = output.trimmingCharacters(in: .whitespacesAndNewlines)
                    trimmed.isEmpty ? resumer.resume(.failure(ClaudeCLIError.noOutput)) : resumer.resume(.success(trimmed))
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
                resumer.resume(.failure(ClaudeCLIError.timedOut))
            }
        }
    }

    private func findClaudeExecutable() throws -> URL {
        let candidates = [
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

        guard process.terminationStatus == 0 else { throw ClaudeCLIError.executableNotFound }
        let path = String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !path.isEmpty, FileManager.default.isExecutableFile(atPath: path) else {
            throw ClaudeCLIError.executableNotFound
        }
        return URL(fileURLWithPath: path)
    }
}
