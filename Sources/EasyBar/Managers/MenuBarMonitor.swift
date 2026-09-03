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
        let hasStatusBar: Bool
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
        let appsWithStatus = getAppsWithStatusBar()
        let items = getMenuItemsFromRunningApps(hasStatusBarIDs: appsWithStatus)
        let hiddenIDs = settingsStore.hiddenBundleIDs

        menuBarItems = items.map { item in
            var mutableItem = item
            if hiddenIDs.contains(item.id) {
                mutableItem.isHidden = true
            }
            return mutableItem
        }
    }

    private func getAppsWithStatusBar() -> Set<String> {
        var statusAppIDs = Set<String>()

        if let windows = CGWindowListCopyWindowInfo(.optionOnScreenOnly, kCGNullWindowID) as? [[String: Any]] {
            for window in windows {
                guard let ownerPID = window[kCGWindowOwnerPID as String] as? pid_t,
                      let layer = window[kCGWindowLayer as String] as? Int,
                      layer == 25 else { continue }

                if let app = NSWorkspace.shared.runningApplications.first(where: { $0.processIdentifier == ownerPID }),
                   let bundleID = app.bundleIdentifier {
                    statusAppIDs.insert(bundleID)
                }
            }
        }

        for app in NSWorkspace.shared.runningApplications {
            guard app.activationPolicy == .regular else { continue }
            if app.activationPolicy == .regular && !app.isTerminated {
                if let windows = CGWindowListCopyWindowInfo(.optionOnScreenOnly, kCGNullWindowID) as? [[String: Any]] {
                    for window in windows {
                        guard let ownerPID = window[kCGWindowOwnerPID as String] as? pid_t,
                              ownerPID == app.processIdentifier else { continue }

                        let bounds = window[kCGWindowBounds as String] as? [String: Any] ?? [:]
                        let y = bounds["Y"] as? Double ?? 100
                        let h = bounds["Height"] as? Double ?? 0

                        if y < 40 && h < 40 {
                            if let bundleID = app.bundleIdentifier {
                                statusAppIDs.insert(bundleID)
                            }
                        }
                    }
                }
            }
        }

        return statusAppIDs
    }

    private func getMenuItemsFromRunningApps(hasStatusBarIDs: Set<String>) -> [MenuBarItem] {
        var items: [MenuBarItem] = []
        let runningApps = NSWorkspace.shared.runningApplications

        for app in runningApps {
            guard app.activationPolicy == .regular,
                  let bundleID = app.bundleIdentifier,
                  let name = app.localizedName else {
                continue
            }

            let isHiddenApp = app.isHidden
            let hasStatusBar = hasStatusBarIDs.contains(bundleID)

            let item = MenuBarItem(
                id: bundleID,
                bundleIdentifier: bundleID,
                processName: name,
                isHidden: false,
                icon: app.icon,
                hasStatusBar: hasStatusBar,
                isBackground: isHiddenApp && !hasStatusBar
            )
            items.append(item)
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
