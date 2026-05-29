import SwiftUI
import AppKit

@main
struct TuckApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var store: TodoStore
    @StateObject private var settings: AppSettings

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
    static let sharedStore = TodoStore()
    static let sharedSettings = AppSettings()

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
    }
}
