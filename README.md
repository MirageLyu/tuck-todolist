# Tuck

Tuck is a tiny macOS menu bar todo app for quickly capturing tasks without opening a full task manager.

It lives in the menu bar, keeps a compact pending list, and can use the local Claude CLI to turn natural language into structured todos. If Claude is unavailable, Tuck safely falls back to saving your original text as the todo title.

## Features

- Menu-bar-only macOS app
- Fast todo capture from a compact dropdown
- Claude-powered natural-language capture through the local `claude` CLI
- Automatic fallback to plain todo creation when Claude is unavailable
- Pending and completed todo sections
- Inline completion and deletion
- Compact editor with autosave
- Expandable notes editor for longer notes
- Chinese / English UI switching
- Local JSON persistence with backup recovery
- Minimal `.app` and `.dmg` build scripts

## Requirements

- macOS 14 or later
- Swift toolchain / Xcode command line tools
- Optional: Claude Code CLI installed and logged in for AI capture

Tuck works without Claude. The **Add** / **记下** button tries Claude first, then falls back to creating a plain todo using the entered text.

## Run from source

```bash
swift run --package-path . Tuck
```

Tuck is an accessory/menu bar app, so it will not open a normal main window.

## Build

```bash
swift build --package-path .
```

## Build the app bundle

```bash
./scripts/build-app.sh
```

Output:

```text
build/Tuck.app
```

## Build the DMG

```bash
./scripts/build-dmg.sh
```

Output:

```text
build/Tuck.dmg
```

The generated app is not code-signed or notarized yet.

## Data storage

Tuck stores data locally at:

```text
~/Library/Application Support/Tuck/todos.json
```

Before overwriting the JSON file, Tuck writes a backup:

```text
~/Library/Application Support/Tuck/todos.json.bak
```

If the main JSON file cannot be loaded, Tuck attempts to recover from the backup.

Older data from the previous development name is migrated from:

```text
~/Library/Application Support/TodoAgent/todos.json
```

## Claude integration

Tuck invokes Claude only from the capture button path. Other actions — editing, completing, deleting, changing language, and expanding sections — never call Claude.

The app uses the local CLI in non-interactive mode. You can verify your setup with:

```bash
claude --print --output-format text --no-session-persistence 'Return exactly: OK'
```

## Development notes

- The app is intentionally small and menu-bar-only.
- There is no sync, projects, tags UI, reminders engine, signing, or notarization yet.
- Build artifacts are ignored via `.gitignore`.
