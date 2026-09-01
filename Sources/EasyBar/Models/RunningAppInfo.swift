import AppKit
import Foundation

struct RunningAppInfo: Identifiable, Hashable {
    let id: String
    let name: String
    let bundleIdentifier: String
    let processIdentifier: pid_t
    let activationPolicy: NSApplication.ActivationPolicy
    let icon: NSImage?
    let launchDate: Date?
    let isActive: Bool

    var displayBundleIdentifier: String {
        bundleIdentifier.isEmpty ? "Unknown bundle" : bundleIdentifier
    }

    var categoryName: String {
        switch activationPolicy {
        case .regular:
            return "App"
        case .accessory:
            return "Utility"
        case .prohibited:
            return "Background"
        @unknown default:
            return "Other"
        }
    }
}
