import SwiftUI

struct MenuBarView: View {
    @ObservedObject var store: TodoStore
    @ObservedObject var settings: AppSettings
    @AppStorage("TodoAgent.showEditor") private var showEditor = false
    @AppStorage("TodoAgent.showCompleted") private var showCompleted = false
    @State private var quickInput = ""
    @State private var agent = TodoAgent()
    @State private var selectedTodoID: UUID?
    @State private var draftTitle = ""
    @State private var draftNotes = ""
    @State private var draftPriority: TodoPriority = .normal
    @State private var hasDueDate = false
    @State private var draftDueDate = Date()
    @State private var isEditingNotes = false
    @State private var statusText = ""
    @State private var confirmingDeleteTodoID: UUID?
    @State private var hoveredProgressTodoID: UUID?
    @State private var newProgressContent = ""
    @FocusState private var isQuickInputFocused: Bool

    init(store: TodoStore, settings: AppSettings) {
        self.store = store
        self.settings = settings
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            header
            quickCapture
            todoList
            editorSection
            completedSection
            footer
        }
        .padding(14)
        .frame(width: 372)
        .background(.regularMaterial)
        .onAppear {
            selectInitialTodo()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                isQuickInputFocused = true
            }
        }
        .onChange(of: selectedTodoID) { _, _ in
            confirmingDeleteTodoID = nil
            hoveredProgressTodoID = nil
            newProgressContent = ""
            loadSelectedTodo(resetNotesExpansion: true)
        }
        .onChange(of: store.todos) { _, _ in syncSelectionAfterStoreChange() }
        .onChange(of: draftTitle) { _, _ in autosaveDraft() }
        .onChange(of: draftNotes) { _, _ in autosaveDraft() }
        .onChange(of: draftPriority) { _, _ in autosaveDraft() }
        .onChange(of: hasDueDate) { _, _ in autosaveDraft() }
        .onChange(of: draftDueDate) { _, _ in autosaveDraft() }
    }

    private var header: some View {
        HStack(spacing: 8) {
            Label(settings.strings.appTitle, systemImage: "checklist")
                .font(.headline)
            Text("\(store.pendingTodos.count)")
                .font(.caption.weight(.bold))
                .padding(.horizontal, 7)
                .padding(.vertical, 3)
                .background(Color.accentColor.opacity(0.16))
                .clipShape(Capsule())
            Spacer()
            Button { settings.cycleLanguage() } label: {
                Label(settings.language.shortLabel, systemImage: "globe")
                    .labelStyle(.titleAndIcon)
            }
            .help(settings.strings.languageLabel)
        }
    }

    private var quickCapture: some View {
        VStack(spacing: 7) {
            HStack(spacing: 8) {
                TextField(settings.strings.quickCapture, text: $quickInput)
                    .textFieldStyle(.roundedBorder)
                    .focused($isQuickInputFocused)
                    .onSubmit { Task { await smartCapture() } }
                Button {
                    Task { await smartCapture() }
                } label: {
                    Label(settings.strings.smartCapture, systemImage: "sparkles")
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

    private var todoList: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(settings.strings.pending)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            if store.pendingTodos.isEmpty {
                Text(settings.strings.noPendingTodos)
                    .foregroundStyle(.secondary)
                    .font(.callout)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(10)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            } else {
                ForEach(store.pendingTodos.prefix(6)) { todo in
                    todoRow(todo)
                }
            }
        }
    }

    private func todoRow(_ todo: TodoItem) -> some View {
        HStack(spacing: 8) {
            Button {
                store.setCompleted(todo, completed: todo.status != .completed)
                statusText = settings.strings.updatedWithAgent
            } label: {
                Image(systemName: todo.status == .completed ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(todo.status == .completed ? .green : .secondary)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text(todo.title)
                        .font(.callout.weight(selectedTodoID == todo.id ? .semibold : .regular))
                        .lineLimit(1)
                        .strikethrough(todo.status == .completed)
                    if !todo.progressEntries.isEmpty {
                        progressBadge(for: todo)
                    }
                }
                if let dueDate = todo.dueDate {
                    Text(dueDate.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if selectedTodoID == todo.id {
                deleteButton(for: todo)
            }
        }
        .padding(10)
        .contentShape(Rectangle())
        .onTapGesture {
            selectedTodoID = todo.id
            showEditor = true
        }
        .background(cardBackground(isSelected: selectedTodoID == todo.id))
        .overlay(cardStroke)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func progressBadge(for todo: TodoItem) -> some View {
        Image(systemName: "list.bullet.clipboard")
            .font(.caption2)
            .foregroundStyle(.blue)
            .popover(isPresented: progressPopoverBinding(for: todo), arrowEdge: .trailing) {
                progressPopover(for: todo)
                    .padding(12)
                    .frame(width: 280)
            }
            .onHover { hovering in
                if hovering {
                    hoveredProgressTodoID = todo.id
                    selectedTodoID = todo.id
                    showEditor = true
                }
            }
            .help(settings.strings.progress)
    }

    private func progressPopoverBinding(for todo: TodoItem) -> Binding<Bool> {
        Binding(
            get: { hoveredProgressTodoID == todo.id && !todo.progressEntries.isEmpty },
            set: { isPresented in
                if isPresented {
                    hoveredProgressTodoID = todo.id
                    selectedTodoID = todo.id
                    showEditor = true
                } else if hoveredProgressTodoID == todo.id {
                    hoveredProgressTodoID = nil
                }
            }
        )
    }

    private func progressPopover(for todo: TodoItem) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(settings.strings.progress)
                .font(.headline)
            ForEach(todo.progressEntries) { entry in
                progressEditorRow(entry, for: todo)
            }
        }
    }

    @ViewBuilder
    private func deleteButton(for todo: TodoItem) -> some View {
        let isConfirming = confirmingDeleteTodoID == todo.id
        Button(role: isConfirming ? .destructive : nil) {
            if isConfirming {
                deleteTodo(todo)
            } else {
                withAnimation(.snappy(duration: 0.18)) {
                    confirmingDeleteTodoID = todo.id
                }
            }
        } label: {
            Group {
                if isConfirming {
                    Text(settings.strings.delete)
                        .font(.caption.weight(.semibold))
                } else {
                    Image(systemName: "trash")
                        .font(.caption)
                }
            }
            .foregroundStyle(isConfirming ? .white : .secondary)
            .padding(.horizontal, isConfirming ? 9 : 0)
            .padding(.vertical, isConfirming ? 4 : 0)
            .background {
                if isConfirming {
                    Capsule().fill(Color.red)
                }
            }
        }
        .buttonStyle(.plain)
        .animation(.snappy(duration: 0.18), value: isConfirming)
    }

    private func cardBackground(isSelected: Bool = false) -> Color {
        isSelected ? Color.accentColor.opacity(0.14) : Color.primary.opacity(0.045)
    }

    private var cardStroke: some View {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .stroke(Color.primary.opacity(0.06), lineWidth: 1)
    }

    private var editorSection: some View {
        DisclosureGroup(isExpanded: $showEditor) {
            miniEditor
                .padding(.top, 6)
        } label: {
            Text(settings.strings.editor)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var miniEditor: some View {
        if selectedTodoID != nil {
            VStack(alignment: .leading, spacing: 10) {
                editorField(title: settings.strings.title) {
                    TextField(settings.strings.title, text: $draftTitle)
                        .textFieldStyle(.roundedBorder)
                }

                notesEditor

                editorField(title: settings.strings.priority) {
                    Picker(settings.strings.priority, selection: $draftPriority) {
                        ForEach(TodoPriority.allCases) { priority in
                            Text(priority.displayName).tag(priority)
                        }
                    }
                    .labelsHidden()
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                editorField(title: settings.strings.dueDate) {
                    HStack(spacing: 8) {
                        Toggle("", isOn: $hasDueDate)
                            .toggleStyle(.checkbox)
                            .labelsHidden()
                        if hasDueDate {
                            DatePicker("", selection: $draftDueDate)
                                .labelsHidden()
                                .frame(maxWidth: .infinity, alignment: .leading)
                        } else {
                            Text("—")
                                .foregroundStyle(.secondary)
                            Spacer()
                        }
                    }
                }

                progressEditor

                Text(settings.strings.updatedWithAgent)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(12)
            .background(.ultraThinMaterial)
            .overlay(cardStroke)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        } else {
            Text(settings.strings.selectTodo)
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.vertical, 4)
        }
    }

    private var notesEditor: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(settings.strings.notes)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                Button(isEditingNotes ? settings.strings.collapse : settings.strings.expand) {
                    isEditingNotes.toggle()
                }
                .font(.caption2)
                .buttonStyle(.borderless)
            }

            if isEditingNotes {
                TextEditor(text: $draftNotes)
                    .font(.callout)
                    .scrollContentBackground(.hidden)
                    .padding(6)
                    .frame(height: 96)
                    .background(Color.primary.opacity(0.045))
                    .overlay(cardStroke)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            } else {
                Button {
                    isEditingNotes = true
                } label: {
                    Text(draftNotes.isEmpty ? settings.strings.notesPlaceholder : draftNotes)
                        .font(.callout)
                        .foregroundStyle(draftNotes.isEmpty ? .secondary : .primary)
                        .lineLimit(2)
                        .frame(maxWidth: .infinity, minHeight: 34, alignment: .topLeading)
                        .padding(8)
                        .background(Color.primary.opacity(0.045))
                        .overlay(cardStroke)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var progressEditor: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(settings.strings.progress)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
            }

            if let todo = selectedTodo, !todo.progressEntries.isEmpty {
                VStack(spacing: 6) {
                    ForEach(todo.progressEntries) { entry in
                        progressEditorRow(entry, for: todo)
                    }
                }
            }

            HStack(spacing: 6) {
                TextField(settings.strings.progressPlaceholder, text: $newProgressContent)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit { addProgressToSelectedTodo() }
                Button(settings.strings.addProgress) {
                    addProgressToSelectedTodo()
                }
                .disabled(newProgressContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
    }

    private func progressEditorRow(_ entry: TodoProgressEntry, for todo: TodoItem) -> some View {
        HStack(alignment: .top, spacing: 6) {
            VStack(alignment: .leading, spacing: 3) {
                Text(entry.createdAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                TextField(settings.strings.progress, text: progressBinding(todo: todo, entry: entry), axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(1...3)
            }
            Button(role: .destructive) {
                store.deleteProgress(todo: todo, entry: entry)
            } label: {
                Image(systemName: "minus.circle")
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
    }

    private var selectedTodo: TodoItem? {
        guard let selectedTodoID else { return nil }
        return store.todos.first { $0.id == selectedTodoID }
    }

    private func progressBinding(todo: TodoItem, entry: TodoProgressEntry) -> Binding<String> {
        Binding(
            get: {
                store.todos
                    .first { $0.id == todo.id }?
                    .progressEntries
                    .first { $0.id == entry.id }?
                    .content ?? entry.content
            },
            set: { value in
                store.updateProgress(todo: todo, entry: entry, content: value)
            }
        )
    }

    private func addProgressToSelectedTodo() {
        guard let selectedTodo else { return }
        store.addProgress(to: selectedTodo, content: newProgressContent)
        newProgressContent = ""
    }

    private func editorField<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
            content()
        }
    }

    @ViewBuilder
    private var completedSection: some View {
        if !store.completedTodos.isEmpty {
            DisclosureGroup(isExpanded: $showCompleted) {
                VStack(spacing: 6) {
                    ForEach(store.completedTodos.prefix(5)) { todo in
                        todoRow(todo)
                            .opacity(0.65)
                    }
                }
                .padding(.top, 6)
            } label: {
                Text("\(settings.strings.completed) · \(store.completedTodos.count)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var footer: some View {
        HStack {
            Text(settings.strings.pendingSummary(store.pendingTodos.count, completed: store.completedTodos.count))
                .font(.caption2)
                .foregroundStyle(.secondary)
            Spacer()
            Button(settings.strings.quit) {
                NSApplication.shared.terminate(nil)
            }
        }
    }

    private func smartCapture() async {
        let text = quickInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, !store.isAgentWorking else { return }
        quickInput = ""
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
                statusText = settings.strings.updatedWithAgent
                selectedTodoID = store.selectedTodoID ?? store.pendingTodos.first?.id
                loadSelectedTodo(resetNotesExpansion: true)
            }
        } catch {
            addFallbackTodo(text)
            statusText = settings.strings.fallbackAdded
        }
    }

    private func addFallbackTodo(_ text: String) {
        store.addTodo(title: text)
        selectedTodoID = store.selectedTodoID
        loadSelectedTodo(resetNotesExpansion: true)
        statusText = settings.strings.added
    }

    private func selectInitialTodo() {
        if selectedTodoID == nil {
            selectedTodoID = store.selectedTodoID ?? store.pendingTodos.first?.id ?? store.completedTodos.first?.id
        }
        loadSelectedTodo(resetNotesExpansion: true)
    }

    private func syncSelectionAfterStoreChange() {
        guard let selectedTodoID, store.todos.contains(where: { $0.id == selectedTodoID }) else {
            self.selectedTodoID = store.pendingTodos.first?.id ?? store.completedTodos.first?.id
            loadSelectedTodo(resetNotesExpansion: true)
            return
        }
        loadSelectedTodo(resetNotesExpansion: false)
    }

    private func loadSelectedTodo(resetNotesExpansion: Bool = false) {
        guard let selectedTodoID, let todo = store.todos.first(where: { $0.id == selectedTodoID }) else {
            draftTitle = ""
            draftNotes = ""
            draftPriority = .normal
            hasDueDate = false
            draftDueDate = Date()
            if resetNotesExpansion { isEditingNotes = false }
            return
        }
        draftTitle = todo.title
        draftNotes = todo.notes
        if resetNotesExpansion { isEditingNotes = false }
        draftPriority = todo.priority
        hasDueDate = todo.dueDate != nil
        draftDueDate = todo.dueDate ?? Date()
    }

    private func autosaveDraft() {
        guard let selectedTodoID, let todo = store.todos.first(where: { $0.id == selectedTodoID }) else { return }
        let trimmedTitle = draftTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return }
        var updated = todo
        updated.title = trimmedTitle
        updated.notes = draftNotes
        updated.priority = draftPriority
        updated.dueDate = hasDueDate ? draftDueDate : nil
        guard updated != todo else { return }
        store.updateTodo(updated)
    }

    private func deleteTodo(_ todo: TodoItem) {
        confirmingDeleteTodoID = nil
        store.deleteTodo(todo)
        self.selectedTodoID = store.pendingTodos.first?.id ?? store.completedTodos.first?.id
        loadSelectedTodo(resetNotesExpansion: true)
        statusText = settings.strings.delete
    }
}
