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

        let apps = NSWorkspace.shared.runningApplications.filter {
            $0.bundleIdentifier == bundleIdentifier
        }

        guard let app = apps.first else { return false }

        let axApp = AXUIElementCreateApplication(app.processIdentifier)
        var menuBarRef: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(axApp, kAXMenuBarAttribute as CFString, &menuBarRef)

        guard result == .success, let menuBar = menuBarRef as! AXUIElement? else {
            return false
        }

        return hideMenuItems(in: menuBar)
    }

    func showMenuBarIcon(bundleIdentifier: String) -> Bool {
        guard isAuthorized else { return false }

        let apps = NSWorkspace.shared.runningApplications.filter {
            $0.bundleIdentifier == bundleIdentifier
        }

        guard let app = apps.first else { return false }

        let axApp = AXUIElementCreateApplication(app.processIdentifier)
        var menuBarRef: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(axApp, kAXMenuBarAttribute as CFString, &menuBarRef)

        guard result == .success, let menuBar = menuBarRef as! AXUIElement? else {
            return false
        }

        return showMenuItems(in: menuBar)
    }

    private func hideMenuItems(in element: AXUIElement) -> Bool {
        var childrenRef: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(element, kAXChildrenAttribute as CFString, &childrenRef)

        guard result == .success, let children = childrenRef as? [AXUIElement] else {
            return false
        }

        var hidden = false
        for child in children {
            var roleRef: CFTypeRef?
            AXUIElementCopyAttributeValue(child, kAXRoleAttribute as CFString, &roleRef)

            if let role = roleRef as? String, role == kAXMenuBarItemRole as String {
                AXUIElementSetAttributeValue(child, kAXHiddenAttribute as CFString, true as CFTypeRef)
                hidden = true
            }
        }
        return hidden
    }

    private func showMenuItems(in element: AXUIElement) -> Bool {
        var childrenRef: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(element, kAXChildrenAttribute as CFString, &childrenRef)

        guard result == .success, let children = childrenRef as? [AXUIElement] else {
            return false
        }

        var shown = false
        for child in children {
            var roleRef: CFTypeRef?
            AXUIElementCopyAttributeValue(child, kAXRoleAttribute as CFString, &roleRef)

            if let role = roleRef as? String, role == kAXMenuBarItemRole as String {
                AXUIElementSetAttributeValue(child, kAXHiddenAttribute as CFString, false as CFTypeRef)
                shown = true
            }
        }
        return shown
    }
}
