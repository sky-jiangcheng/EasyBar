import AppKit
import Observation

@Observable
@MainActor
final class AccessibilityManager {
    var isAuthorized = false
    var showPermissionAlert = false

    init() {
        checkAuthorization()
    }

    func checkAuthorization() {
        isAuthorized = AXIsProcessTrusted()
    }

    func requestAuthorization() {
        checkAuthorization()
        if !isAuthorized {
            showPermissionAlert = true
        }
    }

    func openAccessibilitySettings() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
        NSWorkspace.shared.open(url)
    }

    func hideMenuBarIcon(bundleIdentifier: String) -> Bool {
        guard isAuthorized else { return false }
        return setStatusBarItemHidden(bundleIdentifier: bundleIdentifier, hidden: true)
    }

    func showMenuBarIcon(bundleIdentifier: String) -> Bool {
        guard isAuthorized else { return false }
        return setStatusBarItemHidden(bundleIdentifier: bundleIdentifier, hidden: false)
    }

    private func setStatusBarItemHidden(bundleIdentifier: String, hidden: Bool) -> Bool {
        guard let app = NSWorkspace.shared.runningApplications.first(where: { $0.bundleIdentifier == bundleIdentifier }) else {
            return false
        }

        let axApp = AXUIElementCreateApplication(app.processIdentifier)

        guard let statusItems = getStatusBarItems(for: axApp) else {
            return false
        }

        var success = false
        for item in statusItems {
            AXUIElementSetAttributeValue(item, kAXHiddenAttribute as CFString, hidden as CFTypeRef)
            success = true
        }
        return success
    }

    private func getStatusBarItems(for axApp: AXUIElement) -> [AXUIElement]? {
        var statusItemsRef: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(axApp, "AXStatusLabel" as CFString, &statusItemsRef)

        if result == .success, let items = statusItemsRef as? [AXUIElement], !items.isEmpty {
            return items
        }

        var menubarRef: CFTypeRef?
        let menubarResult = AXUIElementCopyAttributeValue(axApp, kAXMenuBarAttribute as CFString, &menubarRef)

        guard menubarResult == .success else {
            return nil
        }

        let menubar = menubarRef as! AXUIElement

        var childrenRef: CFTypeRef?
        let childrenResult = AXUIElementCopyAttributeValue(menubar, kAXChildrenAttribute as CFString, &childrenRef)

        guard childrenResult == .success, let children = childrenRef as? [AXUIElement] else {
            return nil
        }

        return children
    }
}
