import SwiftUI
import AppKit

@main
struct TuckApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var store: TodoStore
    @StateObject private var settings: AppSettings

    static var isUITesting: Bool {
        CommandLine.arguments.contains("--uitesting")
    }

    static var dataDirectory: URL? {
        guard let index = CommandLine.arguments.firstIndex(of: "--data-dir"),
              index + 1 < CommandLine.arguments.count else { return nil }
        let path = CommandLine.arguments[index + 1]
        var isDir: ObjCBool = false
        guard FileManager.default.fileExists(atPath: path, isDirectory: &isDir), isDir.boolValue else { return nil }
        return URL(fileURLWithPath: path)
    }

    init() {
        _store = StateObject(wrappedValue: AppDelegate.sharedStore)
        _settings = StateObject(wrappedValue: AppDelegate.sharedSettings)
    }

    var body: some Scene {
        MenuBarExtra("Tuck", systemImage: "checklist") {
            MenuBarView(store: store, settings: settings)
        }
        .menuBarExtraStyle(.window)
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    static let sharedStore: TodoStore = {
        if let dataDir = TuckApp.dataDirectory {
            return TodoStore(dataDirectory: dataDir)
        }
        return TodoStore()
    }()
    static let sharedSettings = AppSettings()

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        if TuckApp.isUITesting {
            openUITestingWindow()
        }
    }

    private func openUITestingWindow() {
        let window = NSWindow(
            contentRect: NSRect(x: 100, y: 100, width: 400, height: 700),
            styleMask: [.titled, .closable, .resizable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Tuck (UI Testing)"
        window.contentView = NSHostingView(
            rootView: MenuBarView(store: AppDelegate.sharedStore, settings: AppDelegate.sharedSettings)
                .frame(minWidth: 372, minHeight: 500)
        )
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
