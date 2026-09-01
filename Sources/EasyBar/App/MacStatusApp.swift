import AppKit
import SwiftUI

@main
struct EasyBarApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @State private var settingsStore = SettingsStore()
    @State private var accessibilityManager = AccessibilityManager()

    var body: some Scene {
        Window("EasyBar", id: "main") {
            ContentView()
                .environment(settingsStore)
                .environment(appDelegate.menuBarMonitor)
                .environment(accessibilityManager)
        }
        .defaultSize(width: 520, height: 480)

        Settings {
            SettingsView()
                .environment(settingsStore)
                .environment(appDelegate.menuBarMonitor)
                .environment(accessibilityManager)
        }
        .defaultSize(width: 520, height: 480)
    }

    init() {}
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, ObservableObject {
    private var statusBarController: StatusBarManager?
    private(set) var aggregationPanel: AggregationPanel?

    private var settingsStore = SettingsStore()
    private var accessibilityManager = AccessibilityManager()
    private(set) lazy var menuBarMonitor = MenuBarMonitor(
        accessibilityManager: accessibilityManager,
        settingsStore: settingsStore
    )

    func applicationDidFinishLaunching(_ notification: Notification) {
        aggregationPanel = AggregationPanel(
            menuBarMonitor: menuBarMonitor,
            settingsStore: settingsStore
        )

        statusBarController = StatusBarManager(
            aggregationPanel: aggregationPanel!,
            menuBarMonitor: menuBarMonitor,
            settingsStore: settingsStore,
            accessibilityManager: accessibilityManager
        )

        menuBarMonitor.startMonitoring()
    }
}
