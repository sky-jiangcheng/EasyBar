import AppKit
import Observation

@Observable
@MainActor
final class AccessibilityManager {
    var isAuthorized = false
    var authorizationStatus: AuthorizationStatus = .notDetermined
    var showPermissionAlert = false

    enum AuthorizationStatus: String {
        case notDetermined = "Not Determined"
        case denied = "Denied"
        case authorized = "Authorized"
        case restricted = "Restricted"
    }

    init() {
        checkAuthorization()
    }

    func checkAuthorization() {
        let trusted = AXIsProcessTrusted()
        isAuthorized = trusted
        authorizationStatus = trusted ? .authorized : .denied
    }

    func requestAuthorization() {
        let trusted = AXIsProcessTrusted()
        isAuthorized = trusted
        authorizationStatus = trusted ? .authorized : .denied

        if !trusted {
            showPermissionAlert = true
        }
    }

    func openAccessibilitySettings() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
        NSWorkspace.shared.open(url)
    }

    func hideMenuBarIcon(bundleIdentifier: String) -> Bool {
        guard isAuthorized else { return false }

        let element = AXUIElementCreateSystemWide()
        var appListRef: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(element, kAXChildrenAttribute as CFString, &appListRef)

        guard result == .success, let appList = appListRef as? [AXUIElement] else {
            return false
        }

        for appElement in appList {
            var roleRef: CFTypeRef?
            AXUIElementCopyAttributeValue(appElement, kAXRoleAttribute as CFString, &roleRef)

            guard let role = roleRef as? String, role == kAXMenuBarRole as String else {
                continue
            }

            var childrenRef: CFTypeRef?
            AXUIElementCopyAttributeValue(appElement, kAXChildrenAttribute as CFString, &childrenRef)

            guard let menuItems = childrenRef as? [AXUIElement] else {
                continue
            }

            for menuItem in menuItems {
                var titleRef: CFTypeRef?
                AXUIElementCopyAttributeValue(menuItem, kAXTitleAttribute as CFString, &titleRef)

                if let title = titleRef as? String, title == bundleIdentifier {
                    AXUIElementSetAttributeValue(menuItem, kAXHiddenAttribute as CFString, true as CFTypeRef)
                    return true
                }
            }
        }

        return false
    }

    func showMenuBarIcon(bundleIdentifier: String) -> Bool {
        guard isAuthorized else { return false }

        let element = AXUIElementCreateSystemWide()
        var appListRef: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(element, kAXChildrenAttribute as CFString, &appListRef)

        guard result == .success, let appList = appListRef as? [AXUIElement] else {
            return false
        }

        for appElement in appList {
            var roleRef: CFTypeRef?
            AXUIElementCopyAttributeValue(appElement, kAXRoleAttribute as CFString, &roleRef)

            guard let role = roleRef as? String, role == kAXMenuBarRole as String else {
                continue
            }

            var childrenRef: CFTypeRef?
            AXUIElementCopyAttributeValue(appElement, kAXChildrenAttribute as CFString, &childrenRef)

            guard let menuItems = childrenRef as? [AXUIElement] else {
                continue
            }

            for menuItem in menuItems {
                var titleRef: CFTypeRef?
                AXUIElementCopyAttributeValue(menuItem, kAXTitleAttribute as CFString, &titleRef)

                if let title = titleRef as? String, title == bundleIdentifier {
                    AXUIElementSetAttributeValue(menuItem, kAXHiddenAttribute as CFString, false as CFTypeRef)
                    return true
                }
            }
        }

        return false
    }
}
