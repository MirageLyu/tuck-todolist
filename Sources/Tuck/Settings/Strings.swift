import Foundation

struct Strings {
    let language: AppLanguage

    private var zh: Bool { language.isChinese }

    var appTitle: String { "Tuck" }
    var pending: String { zh ? "待办" : "Pending" }
    var completed: String { zh ? "已完成" : "Completed" }
    var noTodos: String { zh ? "暂无待办" : "No todos" }
    var emptyHint: String { zh ? "试试：明天下午提醒我交房租" : "Try: remind me to pay rent tomorrow afternoon" }
    var quietList: String { zh ? "清爽的一天。随时记录值得记住的事。" : "A quiet list. Capture anything worth remembering." }
    var allClear: String { zh ? "全部完成" : "All clear" }
    var quickAddPlaceholder: String { zh ? "添加待办，或直接描述你想记住的事..." : "Add a todo, or describe it naturally..." }
    var quickAddLabel: String { zh ? "快速添加待办" : "Quick add todo" }
    var add: String { zh ? "添加" : "Add" }
    var details: String { zh ? "详情" : "Details" }
    var selectTodo: String { zh ? "选择一个待办" : "Select a todo" }
    var selectTodoHint: String { zh ? "点击待办即可编辑标题、备注、优先级和日期。" : "Click a todo to edit title, notes, priority, or due date." }
    var title: String { zh ? "标题" : "Title" }
    var notes: String { zh ? "备注" : "Notes" }
    var priority: String { zh ? "优先级" : "Priority" }
    var dueDate: String { zh ? "截止日期" : "Due date" }
    var complete: String { zh ? "完成" : "Complete" }
    var markPending: String { zh ? "标为待办" : "Mark Pending" }
    var delete: String { zh ? "删除" : "Delete" }
    var save: String { zh ? "保存" : "Save" }
    var assistant: String { zh ? "助手" : "Assistant" }
    var assistantSubtitle: String { zh ? "记录和整理你的清单" : "Capture and tidy your list" }
    var tidyPending: String { zh ? "整理未完成" : "Tidy pending" }
    var agentInputPlaceholder: String { zh ? "例如：明天下午提醒我交房租" : "e.g. remind me to pay rent tomorrow afternoon" }
    var send: String { zh ? "发送" : "Send" }
    var initialAssistantMessage: String { zh ? "告诉我你想记录什么，我会帮你整理成 todo。" : "Tell me what to remember and I’ll turn it into todos." }
    var openTodos: String { zh ? "打开" : "Open" }
    var quickCapture: String { zh ? "快速记录" : "Quick capture" }
    var noPendingTodos: String { zh ? "没有待办" : "No pending todos" }
    var languageLabel: String { zh ? "语言" : "Language" }
    var theme: String { zh ? "主题" : "Theme" }
    var smartCapture: String { zh ? "记下" : "Add" }
    var added: String { zh ? "已添加" : "Added" }
    var updated: String { zh ? "已更新" : "Updated" }
    var fallbackAdded: String { zh ? "Claude 不可用，已按普通待办添加" : "Claude unavailable; added as plain todo" }
    var notesPlaceholder: String { zh ? "添加备注..." : "Add notes..." }
    var testClaudeCLI: String { zh ? "测试 Claude" : "Test Claude" }
    var testingClaudeCLI: String { zh ? "正在测试 Claude..." : "Testing Claude..." }
    var claudeCLIAvailable: String { zh ? "Claude 可用" : "Claude Available" }
    var expand: String { zh ? "展开" : "Expand" }
    var collapse: String { zh ? "收起" : "Collapse" }
    var editor: String { zh ? "编辑" : "Editor" }
    var progress: String { zh ? "阶段进展" : "Progress" }
    var progressPlaceholder: String { zh ? "记录阶段进展..." : "Record progress..." }
    var addProgress: String { zh ? "添加进展" : "Add progress" }
    var noProgress: String { zh ? "暂无阶段进展" : "No progress yet" }
    var quit: String { zh ? "退出" : "Quit" }

    func pendingSummary(_ pending: Int, completed: Int) -> String {
        if pending == 0 {
            return completed == 0 ? quietList : "\(allClear) · \(completed) \(self.completed)"
        }
        return "\(pending) \(self.pending)" + (completed > 0 ? " · \(completed) \(self.completed)" : "")
    }

    func agentError(_ message: String) -> String {
        zh ? "Agent 出错：\(message)" : "Agent error: \(message)"
    }

    func tidyPrompt() -> String {
        zh ? "请帮我整理未完成任务，必要时提出建议。" : "Please tidy my pending todos and suggest small improvements if useful."
    }
}
