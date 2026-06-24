# Add Capture Status Summary Design

Date: 2026-06-23

## Context

When a user enters text in Tuck's quick capture field and presses Add, the app sends the text to the local Claude CLI through `TodoAgent` so Claude can decide whether to create, update, complete, or otherwise handle todos. That call can take a noticeable moment. Today the input clears and the todo eventually appears, but the UI gives little feedback during the wait, so the app can feel unresponsive.

## Goal

Make the Add flow feel responsive while Claude is analyzing the todo. The user should immediately see that Tuck is working, then receive a short, user-facing summary of what Claude did once the todo action completes.

## Non-goals

- Do not stream Claude's internal reasoning or chain-of-thought.
- Do not change from the current one-shot Claude CLI flow to a streaming flow.
- Do not redesign the quick capture layout beyond the status/loading feedback needed for this interaction.
- Do not block the fallback path; if Claude fails, Tuck should still add a plain todo.

## Recommended Approach

Use a two-layer feedback model:

1. **Immediate local loading state** while the CLI request is running.
2. **Final Claude-generated status summary** after the response is decoded.

This preserves the current architecture while making the waiting state visible.

## User Experience

When the user clicks Add or submits the quick capture text field:

1. Tuck trims and captures the submitted text.
2. The input clears as it does today.
3. The Add button becomes disabled and changes to a loading affordance such as `Thinking…` / `思考中…` with an optional small spinner.
4. The status area under quick capture shows a deterministic local message:
   - English: `Claude is organizing this todo…`
   - Chinese: `Claude 正在整理这条待办…`
5. When Claude returns actions, Tuck applies them and shows Claude's short status summary if present.
6. If Claude returns no useful summary, Tuck falls back to the existing added/status text.
7. If Claude fails, Tuck keeps the current fallback behavior: add the captured text as a plain todo and show the fallback status.

## Response Format

Extend `AgentResponse` with an optional field:

```json
{
  "reply": "Added it.",
  "statusSummary": "Turned that into a clear todo.",
  "actions": []
}
```

`statusSummary` requirements in the prompt:

- One short user-facing sentence or phrase.
- Describe the handling result, not hidden reasoning.
- Keep it concise: roughly 60 English characters or 20 Chinese characters when possible.
- Prefer concrete summaries such as:
  - `Added this as a follow-up.`
  - `Captured with a due date.`
  - `Marked the matching todo complete.`
- Leave it empty or omit it when there is no useful todo action to summarize.

This is intentionally a progress/result summary, not chain-of-thought.

## Component and State Changes

### `AgentResponse`

Add:

```swift
var statusSummary: String?
```

The field should decode optionally for compatibility with existing responses and tests.

### `TodoAgent.buildPrompt`

Update the response contract in the prompt to ask Claude for `statusSummary`. The prompt should explicitly forbid chain-of-thought and keep the summary brief.

### `MenuBarView.smartCapture()`

Use the existing `store.isAgentWorking` as the loading source of truth.

Before calling Claude:

- Set `store.isAgentWorking = true`.
- Set `statusText` to the localized loading message.

After successful Claude response:

- Apply actions as today.
- Set `statusText` to `response.statusSummary` when non-empty.
- Otherwise use the existing success/fallback status text.

On error:

- Preserve the fallback add behavior.
- Show the existing fallback status.

### UI Presentation

The quick capture Add button should visually reflect `store.isAgentWorking`:

- Disabled while Claude is working.
- Label changes from `Add` to `Thinking…` / `思考中…`, optionally with a small `ProgressView`.

The existing status text area below quick capture is the preferred place for the loading message and final summary. This avoids adding layout complexity.

## Localization

Add localized strings for:

- Quick capture loading status:
  - English: `Claude is organizing this todo…`
  - Chinese: `Claude 正在整理这条待办…`
- Add button loading label:
  - English: `Thinking…`
  - Chinese: `思考中…`

Reuse existing success and fallback strings where possible.

## Error Handling

- If Claude returns malformed JSON, no output, or a CLI error, keep the existing fallback add behavior.
- Do not show raw CLI errors in the quick capture status for this flow.
- Do not leave the UI stuck in loading state; `store.isAgentWorking` must be reset in all paths.
- If `statusSummary` is whitespace-only, ignore it.

## Testing Plan

Add or update tests for:

1. `AgentResponse` decodes `statusSummary` when present and remains compatible when missing.
2. `TodoAgent` prompt includes `statusSummary` in the required JSON contract and tells Claude not to expose chain-of-thought.
3. Quick capture presentation/helper logic shows a loading label/status while `isAgentWorking` is true.
4. Successful capture prefers non-empty `statusSummary` for `statusText`.
5. Whitespace or missing `statusSummary` falls back to existing success text.
6. Error path still adds a plain todo and clears the loading state.

## Verification Plan

- Run `swift test`.
- Build and launch the app.
- Click Add with a todo that triggers Claude handling.
- Confirm the button/status update immediately during the wait.
- Confirm the final todo appears and the final status shows a short Claude summary.
- Confirm a simulated/failing Claude path still adds the plain todo and exits loading state.
