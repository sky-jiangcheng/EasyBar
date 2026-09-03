import AppKit
import Observation

@Observable
@MainActor
final class MenuBarMonitor {
    var menuBarItems: [MenuBarItem] = []
    var isMonitoring = false

    private var timer: Timer?
    private var refreshObserver: Any?
    private let settingsStore: SettingsStore

    enum AppType: String {
        case statusbarOnly = "Status Bar"
        case dockOnly = "Dock"
    }

    struct MenuBarItem: Identifiable, Hashable {
        let id: String
        let bundleIdentifier: String
        let processName: String
        let icon: NSImage?
        let appType: AppType

        func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }

        static func == (lhs: MenuBarItem, rhs: MenuBarItem) -> Bool {
            lhs.id == rhs.id
        }
    }

    init(settingsStore: SettingsStore) {
        self.settingsStore = settingsStore
    }

    func startMonitoring() {
        guard !isMonitoring else { return }
        isMonitoring = true

        refreshMenuItems()
        startTimer()

        refreshObserver = NotificationCenter.default.addObserver(
            forName: .refreshIntervalChanged,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.restartTimer()
            }
        }
    }

    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
        if let observer = refreshObserver {
            NotificationCenter.default.removeObserver(observer)
            refreshObserver = nil
        }
        isMonitoring = false
    }

    private func startTimer() {
        timer?.invalidate()
        let interval = settingsStore.refreshInterval > 0 ? settingsStore.refreshInterval : 2.0
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.refreshMenuItems()
            }
        }
    }

    private func restartTimer() {
        guard isMonitoring else { return }
        startTimer()
    }

    func refreshMenuItems() {
        menuBarItems = getMenuItemsFromRunningApps()
    }

    private func getMenuItemsFromRunningApps() -> [MenuBarItem] {
        var items: [MenuBarItem] = []
        let runningApps = NSWorkspace.shared.runningApplications

        let skipBundleIDs: Set<String> = [
            "com.jiangcheng.EasyBar",
            "com.apple.Spotlight",
            "com.apple.WindowManager",
            "com.apple.notificationcenterui",
            "com.apple.controlcenter",
            "com.apple.controlcenter.helper",
            "com.apple.dock",
            "com.apple.dock.helper",
            "com.apple.dock.extra",
            "com.apple.Siri",
            "com.apple.loginwindow",
            "com.apple.CoreLocationAgent",
            "com.apple.coreservices.uiagent",
            "com.apple.backgroundtaskmanagement.agent",
            "com.apple.SoftwareUpdateNotificationManager",
            "com.apple.UserNotificationCenter",
            "com.apple.Security.keychain-circle-Notification",
            "com.apple.accessibility.universalAccessAuthWarn",
            "com.apple.LocalAuthentication.UIAgent",
            "com.apple.talagent",
            "com.apple.storeuid",
            "com.apple.TextInputMenuAgent",
            "com.apple.TextInputSwitcher",
            "com.apple.wifi.WiFiAgent",
            "com.apple.AirPlayUIAgent",
            "com.apple.universalcontrol",
            "com.apple.AccessibilityUIServer",
            "com.apple.wallpaper.agent",
            "com.apple.PowerChime",
            "com.apple.WorkflowKit.ShortcutsViewService",
            "com.apple.systemuiserver",
        ]

        for app in runningApps {
            guard !app.isTerminated,
                  let bundleID = app.bundleIdentifier,
                  let name = app.localizedName,
                  !bundleID.isEmpty,
                  !name.isEmpty else {
                continue
            }

            if skipBundleIDs.contains(bundleID) { continue }

            if app.activationPolicy == .regular {
                let item = MenuBarItem(
                    id: bundleID,
                    bundleIdentifier: bundleID,
                    processName: name,
                    icon: app.icon,
                    appType: .dockOnly
                )
                items.append(item)
            } else if app.activationPolicy == .accessory {
                guard !bundleID.hasPrefix("com.apple.WebKit.") else { continue }
                guard !bundleID.hasPrefix("com.apple.") else { continue }

                let dominatedByParent = runningApps.contains { other in
                    other.bundleIdentifier != bundleID
                        && other.activationPolicy == .regular
                        && bundleID.hasPrefix((other.bundleIdentifier ?? "").components(separatedBy: ".").prefix(2).joined(separator: "."))
                }
                guard !dominatedByParent else { continue }

                let item = MenuBarItem(
                    id: bundleID,
                    bundleIdentifier: bundleID,
                    processName: name,
                    icon: app.icon,
                    appType: .statusbarOnly
                )
                items.append(item)
            }
        }

        return items.sorted { $0.processName.localizedCaseInsensitiveCompare($1.processName) == .orderedAscending }
    }

    func quitApp(_ item: MenuBarItem) {
        guard let app = NSWorkspace.shared.runningApplications.first(where: { $0.bundleIdentifier == item.bundleIdentifier }) else { return }
        app.terminate()
    }

    func forceQuitApp(_ item: MenuBarItem) {
        guard let app = NSWorkspace.shared.runningApplications.first(where: { $0.bundleIdentifier == item.bundleIdentifier }) else { return }
        app.forceTerminate()
    }

    func activateApp(_ item: MenuBarItem) {
        guard let app = NSWorkspace.shared.runningApplications.first(where: { $0.bundleIdentifier == item.bundleIdentifier }) else { return }
        if item.appType == .statusbarOnly {
            app.unhide()
            NSWorkspace.shared.launchApplication(
                withBundleIdentifier: item.bundleIdentifier,
                options: [],
                additionalEventParamDescriptor: nil,
                launchIdentifier: nil
            )
        } else {
            app.unhide()
            app.activate()
        }
    }
}

extension Notification.Name {
    static let refreshIntervalChanged = Notification.Name("refreshIntervalChanged")
    static let aggregationShouldShow = Notification.Name("aggregationShouldShow")
}
