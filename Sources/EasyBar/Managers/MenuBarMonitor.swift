import AppKit
import Observation

@Observable
@MainActor
final class MenuBarMonitor {
    var menuBarItems: [MenuBarItem] = []
    var isMonitoring = false

    private var timer: Timer?
    private let accessibilityManager: AccessibilityManager
    private let settingsStore: SettingsStore

    struct MenuBarItem: Identifiable, Hashable {
        let id: String
        let bundleIdentifier: String
        let processName: String
        var isHidden: Bool
        var isTemporary: Bool
        let icon: NSImage?

        func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }

        static func == (lhs: MenuBarItem, rhs: MenuBarItem) -> Bool {
            lhs.id == rhs.id
        }
    }

    init(accessibilityManager: AccessibilityManager, settingsStore: SettingsStore) {
        self.accessibilityManager = accessibilityManager
        self.settingsStore = settingsStore
    }

    func startMonitoring() {
        guard !isMonitoring else { return }
        isMonitoring = true

        refreshMenuItems()

        timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.refreshMenuItems()
            }
        }
    }

    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
        isMonitoring = false
    }

    func refreshMenuItems() {
        let items = getMenuItemsFromRunningApps()
        let hiddenIDs = Set(menuBarItems.filter { $0.isHidden }.map { $0.id })

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

        for app in runningApps {
            guard app.activationPolicy == .regular,
                  let bundleID = app.bundleIdentifier,
                  let name = app.localizedName else {
                continue
            }

            let item = MenuBarItem(
                id: bundleID,
                bundleIdentifier: bundleID,
                processName: name,
                isHidden: false,
                isTemporary: false,
                icon: app.icon
            )
            items.append(item)
        }

        return items.sorted { $0.processName.localizedCaseInsensitiveCompare($1.processName) == .orderedAscending }
    }

    func hideItem(_ item: MenuBarItem) {
        guard let index = menuBarItems.firstIndex(where: { $0.id == item.id }) else { return }
        menuBarItems[index].isHidden = true

        if accessibilityManager.isAuthorized {
            _ = accessibilityManager.hideMenuBarIcon(bundleIdentifier: item.bundleIdentifier)
        }
    }

    func showItem(_ item: MenuBarItem) {
        guard let index = menuBarItems.firstIndex(where: { $0.id == item.id }) else { return }
        menuBarItems[index].isHidden = false
        menuBarItems[index].isTemporary = false

        if accessibilityManager.isAuthorized {
            _ = accessibilityManager.showMenuBarIcon(bundleIdentifier: item.bundleIdentifier)
        }
    }

    func showTemporarily(_ item: MenuBarItem) {
        guard let index = menuBarItems.firstIndex(where: { $0.id == item.id }) else { return }
        menuBarItems[index].isHidden = false
        menuBarItems[index].isTemporary = true

        if accessibilityManager.isAuthorized {
            _ = accessibilityManager.showMenuBarIcon(bundleIdentifier: item.bundleIdentifier)
        }

        scheduleAutoHide(for: item)
    }

    private func scheduleAutoHide(for item: MenuBarItem) {
        let delay = settingsStore.autoHideDelay
        Task {
            try? await Task.sleep(for: .seconds(delay))
            guard !Task.isCancelled else { return }

            if let index = menuBarItems.firstIndex(where: { $0.id == item.id }),
               menuBarItems[index].isTemporary {
                menuBarItems[index].isHidden = true
                menuBarItems[index].isTemporary = false

                if accessibilityManager.isAuthorized {
                    _ = accessibilityManager.hideMenuBarIcon(bundleIdentifier: item.bundleIdentifier)
                }
            }
        }
    }
}
