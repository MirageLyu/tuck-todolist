# Tuck

Tuck is a small macOS menu bar todo app for capturing tasks the moment they come to mind.

It stays out of the way until you need it. Click the checklist icon in the menu bar, type something you want to remember, and Tuck keeps it in a compact list you can review later. It is designed for quick personal task capture rather than heavy project management.

## What Tuck is for

Tuck is best for small everyday reminders:

- A task you do not want to forget
- A quick note that should become a todo
- A short list of pending things for the day
- A lightweight place to keep tasks without opening a full productivity app

The app is intentionally simple. It focuses on a clean menu bar experience, fast capture, and a calm list that does not demand attention.

## Features

- Lives in the macOS menu bar
- Opens as a compact dropdown
- Quickly add pending todos
- Mark todos as complete
- Edit title, notes, priority, and due date
- Delete with a second confirmation click
- View completed todos separately
- Switch between English and Chinese
- Stores your todos locally on your Mac
- Optional natural-language capture when Claude Code CLI is available

Tuck works even if Claude is not available. In that case, it simply saves what you typed as a normal todo.

## Build from source

### Requirements

- macOS 14 or later
- Xcode Command Line Tools or Xcode
- Swift toolchain

### Clone the repository

```bash
git clone https://github.com/MirageLyu/tuck-todolist.git
cd tuck-todolist
```

### Run from source

```bash
swift run Tuck
```

Tuck is a menu bar app, so it will appear in the macOS menu bar instead of opening a normal app window.

### Build the app

```bash
./scripts/build-app.sh
```

The app bundle will be created at:

```text
build/Tuck.app
```

### Build the DMG installer

```bash
./scripts/build-dmg.sh
```

The installer will be created at:

```text
build/Tuck.dmg
```

Open the DMG, then drag **Tuck** into **Applications**.

## Notes

Tuck is currently an unsigned local build. Depending on your macOS security settings, you may need to allow it from System Settings the first time you open it.
