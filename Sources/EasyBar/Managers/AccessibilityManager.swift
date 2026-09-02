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
}
