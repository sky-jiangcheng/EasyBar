import AppKit
import SwiftUI

@main
struct EasyBarApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        Window("EasyBar", id: "main") {
            ContentView()
                .environment(appDelegate.settingsStore)
                .environment(appDelegate.menuBarMonitor)
                .environment(appDelegate.accessibilityManager)
        }
        .defaultSize(width: 700, height: 450)

        Settings {
            SettingsView()
                .environment(appDelegate.settingsStore)
                .environment(appDelegate.menuBarMonitor)
                .environment(appDelegate.accessibilityManager)
        }
        .defaultSize(width: 520, height: 480)
    }

    init() {}
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, ObservableObject {
    private var statusBarController: StatusBarManager?

    let settingsStore = SettingsStore()
    let accessibilityManager = AccessibilityManager()

    private(set) lazy var menuBarMonitor = MenuBarMonitor(
        accessibilityManager: accessibilityManager,
        settingsStore: settingsStore
    )

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusBarController = StatusBarManager(
            menuBarMonitor: menuBarMonitor,
            settingsStore: settingsStore,
            accessibilityManager: accessibilityManager
        )

        menuBarMonitor.startMonitoring()
    }
}
