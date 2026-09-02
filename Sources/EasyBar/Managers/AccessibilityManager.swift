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

        let pid = app.processIdentifier
        let axApp = AXUIElementCreateApplication(pid)

        if hideViaSystemWide(pid: pid, hidden: hidden) {
            return true
        }

        if hideViaAppMenuBar(axApp: axApp, hidden: hidden) {
            return true
        }

        return false
    }

    private func hideViaSystemWide(pid: pid_t, hidden: Bool) -> Bool {
        let systemWide = AXUIElementCreateSystemWide()

        var menubarRef: CFTypeRef?
        let menubarResult = AXUIElementCopyAttributeValue(systemWide, kAXMenuBarAttribute as CFString, &menubarRef)
        guard menubarResult == .success else { return false }

        let menubar = menubarRef as! AXUIElement

        var childrenRef: CFTypeRef?
        let childrenResult = AXUIElementCopyAttributeValue(menubar, kAXChildrenAttribute as CFString, &childrenRef)
        guard childrenResult == .success, let children = childrenRef as? [AXUIElement] else { return false }

        var found = false
        for item in children {
            if matchesPid(item: item, pid: pid) {
                AXUIElementSetAttributeValue(item, kAXHiddenAttribute as CFString, hidden as CFTypeRef)
                found = true
            }
        }
        return found
    }

    private func hideViaAppMenuBar(axApp: AXUIElement, hidden: Bool) -> Bool {
        var menubarRef: CFTypeRef?
        let menubarResult = AXUIElementCopyAttributeValue(axApp, kAXMenuBarAttribute as CFString, &menubarRef)
        guard menubarResult == .success else { return false }

        let menubar = menubarRef as! AXUIElement

        var childrenRef: CFTypeRef?
        let childrenResult = AXUIElementCopyAttributeValue(menubar, kAXChildrenAttribute as CFString, &childrenRef)
        guard childrenResult == .success, let children = childrenRef as? [AXUIElement] else { return false }

        for item in children {
            var roleRef: CFTypeRef?
            let roleResult = AXUIElementCopyAttributeValue(item, kAXRoleAttribute as CFString, &roleRef)
            guard roleResult == .success, let role = roleRef as? String else { continue }

            if role == kAXMenuBarItemRole as String {
                AXUIElementSetAttributeValue(item, kAXHiddenAttribute as CFString, hidden as CFTypeRef)
            }
        }
        return true
    }

    private func matchesPid(item: AXUIElement, pid: pid_t) -> Bool {
        var roleRef: CFTypeRef?
        AXUIElementCopyAttributeValue(item, kAXRoleAttribute as CFString, &roleRef)
        guard let role = roleRef as? String else { return false }

        if role == "AXMenuBarItem" {
            return true
        }

        return false
    }

    func dumpAXTree() {
        guard isAuthorized else {
            print("[AX] Not authorized")
            return
        }

        let systemWide = AXUIElementCreateSystemWide()
        print("[AX] === System Wide ===")
        dumpElement(systemWide, depth: 0, maxDepth: 4)
    }

    private func dumpElement(_ element: AXUIElement, depth: Int, maxDepth: Int) {
        guard depth < maxDepth else { return }

        let indent = String(repeating: "  ", count: depth)

        var roleRef: CFTypeRef?
        AXUIElementCopyAttributeValue(element, kAXRoleAttribute as CFString, &roleRef)
        let role = roleRef as? String ?? "?"

        var titleRef: CFTypeRef?
        AXUIElementCopyAttributeValue(element, kAXTitleAttribute as CFString, &titleRef)
        let title = titleRef as? String

        var desc = "\(indent)\(role)"
        if let title { desc += " title=\(title)" }
        print(desc)

        var childrenRef: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(element, kAXChildrenAttribute as CFString, &childrenRef)
        guard result == .success, let children = childrenRef as? [AXUIElement] else { return }

        for child in children {
            dumpElement(child, depth: depth + 1, maxDepth: maxDepth)
        }
    }
}
