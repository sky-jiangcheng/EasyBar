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

    struct MenuBarItem: Identifiable, Hashable {
        let id: String
        let bundleIdentifier: String
        let processName: String
        var isHidden: Bool
        let icon: NSImage?
        let isBackground: Bool

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
        let items = getMenuItemsFromRunningApps()
        let hiddenIDs = settingsStore.hiddenBundleIDs

        menuBarItems = items.map { item in
            var mutableItem = item
            if hiddenIDs.contains(item.id) {
                mutableItem.isHidden = true
            }
            return mutableItem
        }
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

            let isRegular = app.activationPolicy == .regular
            let isAccessory = app.activationPolicy == .accessory

            if isRegular {
                let item = MenuBarItem(
                    id: bundleID,
                    bundleIdentifier: bundleID,
                    processName: name,
                    isHidden: false,
                    icon: app.icon,
                    isBackground: app.isHidden
                )
                items.append(item)
            } else if isAccessory {
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
                    isHidden: false,
                    icon: app.icon,
                    isBackground: true
                )
                items.append(item)
            }
        }

        return items.sorted { $0.processName.localizedCaseInsensitiveCompare($1.processName) == .orderedAscending }
    }

    func hideItem(_ item: MenuBarItem) {
        guard let index = menuBarItems.firstIndex(where: { $0.id == item.id }) else { return }
        menuBarItems[index].isHidden = true

        if !settingsStore.hiddenBundleIDs.contains(item.bundleIdentifier) {
            settingsStore.hiddenBundleIDs.insert(item.bundleIdentifier)
            settingsStore.save()
        }

        NotificationCenter.default.post(name: .aggregationShouldShow, object: nil)
    }

    func showItem(_ item: MenuBarItem) {
        guard let index = menuBarItems.firstIndex(where: { $0.id == item.id }) else { return }
        menuBarItems[index].isHidden = false

        if settingsStore.hiddenBundleIDs.contains(item.bundleIdentifier) {
            settingsStore.hiddenBundleIDs.remove(item.bundleIdentifier)
            settingsStore.save()
        }
    }

    func showTemporarily(_ item: MenuBarItem) {
        guard let index = menuBarItems.firstIndex(where: { $0.id == item.id }) else { return }
        menuBarItems[index].isHidden = false

        scheduleAutoHide(for: item)
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
        app.activate()
    }

    private func scheduleAutoHide(for item: MenuBarItem) {
        guard let delay = settingsStore.autoHideDelay, delay > 0 else { return }

        Task {
            try? await Task.sleep(for: .seconds(delay))
            guard !Task.isCancelled else { return }

            if let index = menuBarItems.firstIndex(where: { $0.id == item.id }),
               !menuBarItems[index].isHidden {
                menuBarItems[index].isHidden = true
            }
        }
    }
}

extension Notification.Name {
    static let refreshIntervalChanged = Notification.Name("refreshIntervalChanged")
    static let aggregationShouldShow = Notification.Name("aggregationShouldShow")
}
