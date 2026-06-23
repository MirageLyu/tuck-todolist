# Capture Status Summary Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add visible loading feedback and a short Claude-generated status summary to Tuck's quick capture Add flow.

**Architecture:** Keep the current one-shot local Claude CLI flow. Extend the decoded `AgentResponse` contract with optional `statusSummary`, set local loading UI state before awaiting Claude, and display the final summary after applying returned actions. Keep fallback behavior unchanged so failed Claude calls still add a plain todo.

**Tech Stack:** Swift, SwiftUI, XCTest, Swift Package Manager, local Claude CLI invoked by `ClaudeCLIClient`.

## Global Constraints

- Do not stream Claude internal reasoning or chain-of-thought.
- Do not change from the current one-shot Claude CLI flow to a streaming flow.
- Do not redesign the quick capture layout beyond status/loading feedback.
- If Claude fails, Tuck still adds a plain todo.
- `statusSummary` is optional and must be ignored when missing or whitespace-only.
- Add localized English and Chinese strings for capture loading status and Add button loading label.
- Run `swift test` after each implementation task that changes code.
- Keep commits small and task-scoped.

---

## File Structure

- `Sources/Tuck/Models/AgentResponse.swift`
  - Owns decoded Claude response data.
  - Add optional `statusSummary` while preserving compatibility with responses that omit it.
- `Sources/Tuck/Agent/TodoAgent.swift`
  - Owns prompt construction and response decoding.
  - Update the JSON schema/prompt rules to request a concise user-facing `statusSummary` and explicitly forbid chain-of-thought.
- `Sources/Tuck/Settings/Strings.swift`
  - Owns localized UI strings.
  - Add `captureThinking` and `captureThinkingStatus` computed properties.
- `Sources/Tuck/Views/MenuBarView.swift`
  - Owns quick capture UI and `smartCapture()` flow.
  - Add a loading button label/spinner while `store.isAgentWorking` is true.
  - Set loading `statusText` before awaiting Claude.
  - Prefer non-empty `response.statusSummary` after successful Claude actions.
- `Tests/TuckTests/AgentResponseTests.swift`
  - New focused tests for `AgentResponse.statusSummary` decoding compatibility.
- `Tests/TuckTests/TodoAgentPromptTests.swift`
  - New focused tests for prompt contract text. This requires making `TodoAgent.buildPrompt(...)` test-visible as `internal`.
- `Tests/TuckTests/StringsLocalizationTests.swift`
  - New focused tests for localized capture loading strings.
- `Tests/TuckTests/QuickCapturePresentationTests.swift`
  - New focused tests for a tiny presentation helper that maps loading state to button title/icon behavior.

---

### Task 1: Decode and Prompt for `statusSummary`

**Files:**
- Modify: `Sources/Tuck/Models/AgentResponse.swift:2-6`
- Modify: `Sources/Tuck/Agent/TodoAgent.swift:34-79`
- Create: `Tests/TuckTests/AgentResponseTests.swift`
- Create: `Tests/TuckTests/TodoAgentPromptTests.swift`

**Interfaces:**
- Consumes: `AgentResponse.reply`, `AgentResponse.actions`, `AgentResponse.dailySummary`.
- Produces: `AgentResponse.statusSummary: String?`.
- Produces: `TodoAgent.buildPrompt(mode:userText:todos:) throws -> String` as `internal` for tests.

- [ ] **Step 1: Write failing `AgentResponse` decode tests**

Create `Tests/TuckTests/AgentResponseTests.swift`:

```swift
import XCTest
@testable import Tuck

final class AgentResponseTests: XCTestCase {
    func testDecodeAgentResponseWithStatusSummary() throws {
        let json = """
        {
          "reply": "Added it.",
          "statusSummary": "Captured with a due date.",
          "actions": []
        }
        """
        let data = try XCTUnwrap(json.data(using: .utf8))

        let response = try JSONDecoder().decode(AgentResponse.self, from: data)

        XCTAssertEqual(response.reply, "Added it.")
        XCTAssertEqual(response.statusSummary, "Captured with a due date.")
        XCTAssertTrue(response.actions.isEmpty)
        XCTAssertNil(response.dailySummary)
    }

    func testDecodeAgentResponseWithoutStatusSummaryRemainsCompatible() throws {
        let json = """
        {
          "reply": "Added it.",
          "actions": []
        }
        """
        let data = try XCTUnwrap(json.data(using: .utf8))

        let response = try JSONDecoder().decode(AgentResponse.self, from: data)

        XCTAssertEqual(response.reply, "Added it.")
        XCTAssertNil(response.statusSummary)
        XCTAssertTrue(response.actions.isEmpty)
    }
}
```

- [ ] **Step 2: Run decode tests and verify failure**

Run: `swift test --filter AgentResponseTests`

Expected: FAIL because `AgentResponse` has no member named `statusSummary` or decoding does not expose it.

- [ ] **Step 3: Write failing prompt contract tests**

Create `Tests/TuckTests/TodoAgentPromptTests.swift`:

```swift
import XCTest
@testable import Tuck

@MainActor
final class TodoAgentPromptTests: XCTestCase {
    func testBuildPromptRequestsStatusSummary() throws {
        let prompt = try TodoAgent().buildPrompt(mode: .capture, userText: "buy milk", todos: [])

        XCTAssertTrue(prompt.contains("\"statusSummary\""), prompt)
        XCTAssertTrue(prompt.contains("short user-facing progress/result summary"), prompt)
        XCTAssertTrue(prompt.contains("Do not include chain-of-thought"), prompt)
    }
}
```

- [ ] **Step 4: Run prompt tests and verify failure**

Run: `swift test --filter TodoAgentPromptTests`

Expected: FAIL because `buildPrompt` is private and/or the prompt does not mention `statusSummary`.

- [ ] **Step 5: Implement `statusSummary` decoding and prompt contract**

Modify `Sources/Tuck/Models/AgentResponse.swift` so the struct becomes:

```swift
import Foundation

struct AgentResponse: Codable {
    var reply: String
    var statusSummary: String?
    var actions: [AgentAction]
    var dailySummary: String?
}
```

Modify `Sources/Tuck/Agent/TodoAgent.swift`:

1. Change `private func buildPrompt` to `internal func buildPrompt`.
2. Replace the `Rules:` and `Response schema:` portion with the following content while preserving the surrounding `Input:` section:

```swift
        Rules:
        - Return JSON only. No markdown fences, no prose outside JSON.
        - Preserve the user's language in titles, replies, and statusSummary.
        - Create todos when the user mentions an actionable thing to remember.
        - Use existing todo IDs for update/complete/delete actions.
        - If the user is only chatting, return an empty actions array.
        - For dueDate, use ISO-8601 dates with timezone when you can infer one; otherwise null.
        - priority must be one of: low, normal, high.
        - Never invent deleted or completed items unless the user clearly asked.
        - statusSummary is a short user-facing progress/result summary, not hidden reasoning.
        - Do not include chain-of-thought, private reasoning, or step-by-step analysis.
        - Keep statusSummary concise: about 60 English characters or 20 Chinese characters when possible.

        Response schema:
        {
          "reply": "short user-facing response",
          "statusSummary": "short user-facing progress/result summary or null",
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
```

- [ ] **Step 6: Run focused tests**

Run: `swift test --filter AgentResponseTests && swift test --filter TodoAgentPromptTests`

Expected: PASS.

- [ ] **Step 7: Commit Task 1**

```bash
git add Sources/Tuck/Models/AgentResponse.swift Sources/Tuck/Agent/TodoAgent.swift Tests/TuckTests/AgentResponseTests.swift Tests/TuckTests/TodoAgentPromptTests.swift
git commit -m "Add Claude capture status summary contract"
```

---

### Task 2: Add Localized Loading Strings

**Files:**
- Modify: `Sources/Tuck/Settings/Strings.swift:35-45`
- Create: `Tests/TuckTests/StringsLocalizationTests.swift`

**Interfaces:**
- Consumes: `Strings.smartCapture`, `Strings.added`, `Strings.fallbackAdded`.
- Produces: `Strings.captureThinking: String`.
- Produces: `Strings.captureThinkingStatus: String`.

- [ ] **Step 1: Write failing localization tests**

Create `Tests/TuckTests/StringsLocalizationTests.swift`:

```swift
import XCTest
@testable import Tuck

final class StringsLocalizationTests: XCTestCase {
    func testCaptureThinkingStringsEnglish() {
        let strings = Strings(language: .english)

        XCTAssertEqual(strings.captureThinking, "Thinking…")
        XCTAssertEqual(strings.captureThinkingStatus, "Claude is organizing this todo…")
    }

    func testCaptureThinkingStringsChinese() {
        let strings = Strings(language: .chinese)

        XCTAssertEqual(strings.captureThinking, "思考中…")
        XCTAssertEqual(strings.captureThinkingStatus, "Claude 正在整理这条待办…")
    }
}
```

- [ ] **Step 2: Run localization tests and verify failure**

Run: `swift test --filter StringsLocalizationTests`

Expected: FAIL because `captureThinking` and `captureThinkingStatus` do not exist.

- [ ] **Step 3: Implement localized strings**

Modify `Sources/Tuck/Settings/Strings.swift` near `smartCapture`, `added`, and `updated`:

```swift
    var smartCapture: String { zh ? "记下" : "Add" }
    var captureThinking: String { zh ? "思考中…" : "Thinking…" }
    var captureThinkingStatus: String { zh ? "Claude 正在整理这条待办…" : "Claude is organizing this todo…" }
    var added: String { zh ? "已添加" : "Added" }
```

- [ ] **Step 4: Run focused tests**

Run: `swift test --filter StringsLocalizationTests`

Expected: PASS.

- [ ] **Step 5: Commit Task 2**

```bash
git add Sources/Tuck/Settings/Strings.swift Tests/TuckTests/StringsLocalizationTests.swift
git commit -m "Add localized capture loading strings"
```

---

### Task 3: Add Quick Capture Loading Presentation

**Files:**
- Modify: `Sources/Tuck/Views/MenuBarView.swift:126-146` and append helper near existing presentation structs after `CLITestTooltipPresentation`.
- Create: `Tests/TuckTests/QuickCapturePresentationTests.swift`

**Interfaces:**
- Consumes: `Strings.smartCapture`, `Strings.captureThinking`, `store.isAgentWorking`.
- Produces: `QuickCapturePresentation.init(isWorking:strings:)`.
- Produces: `QuickCapturePresentation.buttonTitle: String`.
- Produces: `QuickCapturePresentation.systemImage: String`.
- Produces: `QuickCapturePresentation.showsProgress: Bool`.

- [ ] **Step 1: Write failing presentation tests**

Create `Tests/TuckTests/QuickCapturePresentationTests.swift`:

```swift
import XCTest
@testable import Tuck

final class QuickCapturePresentationTests: XCTestCase {
    func testIdlePresentationUsesAddLabelAndSparkles() {
        let presentation = QuickCapturePresentation(isWorking: false, strings: Strings(language: .english))

        XCTAssertEqual(presentation.buttonTitle, "Add")
        XCTAssertEqual(presentation.systemImage, "sparkles")
        XCTAssertFalse(presentation.showsProgress)
    }

    func testWorkingPresentationUsesThinkingLabelAndProgress() {
        let presentation = QuickCapturePresentation(isWorking: true, strings: Strings(language: .english))

        XCTAssertEqual(presentation.buttonTitle, "Thinking…")
        XCTAssertEqual(presentation.systemImage, "sparkles")
        XCTAssertTrue(presentation.showsProgress)
    }
}
```

- [ ] **Step 2: Run presentation tests and verify failure**

Run: `swift test --filter QuickCapturePresentationTests`

Expected: FAIL because `QuickCapturePresentation` does not exist.

- [ ] **Step 3: Implement presentation helper**

Add this helper near the existing presentation helpers at the bottom of `MenuBarView.swift`:

```swift
struct QuickCapturePresentation {
    let buttonTitle: String
    let systemImage: String
    let showsProgress: Bool

    init(isWorking: Bool, strings: Strings) {
        self.buttonTitle = isWorking ? strings.captureThinking : strings.smartCapture
        self.systemImage = "sparkles"
        self.showsProgress = isWorking
    }
}
```

- [ ] **Step 4: Update quick capture button UI**

Modify `private var quickCapture: some View` in `MenuBarView.swift` so the button label uses `QuickCapturePresentation`:

```swift
    private var quickCapture: some View {
        let presentation = QuickCapturePresentation(isWorking: store.isAgentWorking, strings: settings.strings)

        return VStack(spacing: 7) {
            HStack(spacing: 8) {
                TextField(settings.strings.quickCapture, text: $quickInput)
                    .textFieldStyle(.roundedBorder)
                    .focused($isQuickInputFocused)
                    .onSubmit { Task { await smartCapture() } }
                Button {
                    Task { await smartCapture() }
                } label: {
                    HStack(spacing: 5) {
                        if presentation.showsProgress {
                            ProgressView()
                                .controlSize(.mini)
                                .scaleEffect(0.55)
                        }
                        Label(presentation.buttonTitle, systemImage: presentation.systemImage)
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(quickInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || store.isAgentWorking)
            }
            if !statusText.isEmpty {
                Text(statusText)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(10)
        .background(.ultraThinMaterial)
        .overlay(cardStroke)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
```

- [ ] **Step 5: Run focused tests**

Run: `swift test --filter QuickCapturePresentationTests`

Expected: PASS.

- [ ] **Step 6: Run UI-adjacent tests**

Run: `swift test --filter CLITestTooltipPresentationTests && swift test --filter QuickCapturePresentationTests`

Expected: PASS.

- [ ] **Step 7: Commit Task 3**

```bash
git add Sources/Tuck/Views/MenuBarView.swift Tests/TuckTests/QuickCapturePresentationTests.swift
git commit -m "Show quick capture loading state"
```

---

### Task 4: Use Loading Status and Final Claude Summary in `smartCapture()`

**Files:**
- Modify: `Sources/Tuck/Views/MenuBarView.swift:616-646`
- Test: `Tests/TuckTests/QuickCapturePresentationTests.swift` only covers presentation; flow verification uses `swift test` plus manual app verification because `smartCapture()` currently depends on SwiftUI state and `TodoAgent` wiring.

**Interfaces:**
- Consumes: `AgentResponse.statusSummary: String?` from Task 1.
- Consumes: `Strings.captureThinkingStatus` from Task 2.
- Produces: `MenuBarView.preferredCaptureStatus(summary:fallback:) -> String` as an internal pure helper for testability.

- [ ] **Step 1: Add failing pure helper tests**

Append to `Tests/TuckTests/QuickCapturePresentationTests.swift`:

```swift
final class CaptureStatusSummaryTests: XCTestCase {
    func testPreferredCaptureStatusUsesNonEmptySummary() {
        XCTAssertEqual(
            CaptureStatusSummary.preferred(summary: "Captured with a due date.", fallback: "Updated"),
            "Captured with a due date."
        )
    }

    func testPreferredCaptureStatusIgnoresWhitespaceSummary() {
        XCTAssertEqual(
            CaptureStatusSummary.preferred(summary: "   \n", fallback: "Updated"),
            "Updated"
        )
    }

    func testPreferredCaptureStatusUsesFallbackWhenSummaryMissing() {
        XCTAssertEqual(
            CaptureStatusSummary.preferred(summary: nil, fallback: "Updated"),
            "Updated"
        )
    }
}
```

- [ ] **Step 2: Run helper tests and verify failure**

Run: `swift test --filter CaptureStatusSummaryTests`

Expected: FAIL because `CaptureStatusSummary` does not exist.

- [ ] **Step 3: Implement summary helper**

Add near `QuickCapturePresentation` in `MenuBarView.swift`:

```swift
struct CaptureStatusSummary {
    static func preferred(summary: String?, fallback: String) -> String {
        let trimmed = summary?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmed.isEmpty ? fallback : trimmed
    }
}
```

- [ ] **Step 4: Update `smartCapture()` loading and success status**

Modify `smartCapture()` in `MenuBarView.swift`:

```swift
    private func smartCapture() async {
        let text = quickInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, !store.isAgentWorking else { return }
        quickInput = ""
        statusText = settings.strings.captureThinkingStatus
        store.isAgentWorking = true
        defer { store.isAgentWorking = false }

        do {
            let response = try await agent.run(mode: .capture, userText: text, todos: store.todos)
            if response.actions.isEmpty {
                addFallbackTodo(text)
            } else {
                store.addMessage(role: .user, text: text)
                store.apply(response.actions)
                store.addMessage(role: .assistant, text: response.reply)
                statusText = CaptureStatusSummary.preferred(summary: response.statusSummary, fallback: settings.strings.updated)
                selectedTodoID = store.selectedTodoID ?? store.pendingTodos.first?.id
                loadSelectedTodo(resetNotesExpansion: true)
            }
        } catch {
            addFallbackTodo(text)
            statusText = settings.strings.fallbackAdded
        }
    }
```

- [ ] **Step 5: Run helper tests**

Run: `swift test --filter CaptureStatusSummaryTests`

Expected: PASS.

- [ ] **Step 6: Run full tests**

Run: `swift test`

Expected: all tests pass with 0 failures.

- [ ] **Step 7: Commit Task 4**

```bash
git add Sources/Tuck/Views/MenuBarView.swift Tests/TuckTests/QuickCapturePresentationTests.swift
git commit -m "Use Claude capture status summary"
```

---

### Task 5: Manual App Verification

**Files:**
- No source files expected.

**Interfaces:**
- Consumes: completed Tasks 1-4.
- Produces: verified behavior in the running macOS app.

- [ ] **Step 1: Run full test suite**

Run: `swift test`

Expected: all tests pass with 0 failures.

- [ ] **Step 2: Clean build**

Run: `swift build`

Expected: build completes successfully.

- [ ] **Step 3: Stop old Tuck process**

Run: `pkill -x Tuck || true`

Expected: command exits successfully whether or not Tuck was running.

- [ ] **Step 4: Launch app**

Run: `.build/debug/Tuck &`

Expected: Tuck launches as a menu bar app.

- [ ] **Step 5: Verify quick capture loading feedback**

Manual check:

1. Open Tuck from the menu bar.
2. Enter a natural-language todo such as `tomorrow afternoon remind me to pay rent`.
3. Click Add.
4. Confirm immediately:
   - Add button is disabled.
   - Button shows `Thinking…` or `思考中…` depending on app language.
   - Status text shows `Claude is organizing this todo…` or `Claude 正在整理这条待办…`.
5. Wait for Claude to finish.
6. Confirm:
   - Todo appears or an existing todo is updated.
   - Status text shows a short summary if Claude returned one, otherwise `Updated`.
   - Button returns to normal Add state.

- [ ] **Step 6: Verify fallback behavior if practical**

If it is practical to make Claude unavailable temporarily, rename or move the Claude executable outside the app's searched paths, launch Tuck, and Add a todo. Confirm the plain todo is added and status says `Claude unavailable; added as plain todo` / `Claude 不可用，已按普通待办添加`. Restore the Claude executable immediately after the check.

Do not leave the local Claude CLI unavailable after this step.

- [ ] **Step 7: Final status check**

Run: `git status --short`

Expected: only intentional committed branch changes or clean working tree.

- [ ] **Step 8: Commit any verification doc update only if one was created**

No commit is required if no files changed during verification.
