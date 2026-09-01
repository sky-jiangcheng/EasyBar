import AppKit
import Foundation
import Observation

@Observable
@MainActor
final class RunningAppsStore {
    var apps: [RunningAppInfo] = []
    var lastRefreshDate = Date()

    var regularApps: [RunningAppInfo] {
        apps.filter { $0.activationPolicy == .regular }
    }

    var backgroundApps: [RunningAppInfo] {
        apps.filter { $0.activationPolicy != .regular }
    }

    func refresh() {
        let frontmostPID = NSWorkspace.shared.frontmostApplication?.processIdentifier
        apps = NSWorkspace.shared.runningApplications
            .filter { !$0.isTerminated }
            .map { app in
                RunningAppInfo(
                    id: app.bundleIdentifier ?? "pid-\(app.processIdentifier)",
                    name: app.localizedName ?? "Process \(app.processIdentifier)",
                    bundleIdentifier: app.bundleIdentifier ?? "",
                    processIdentifier: app.processIdentifier,
                    activationPolicy: app.activationPolicy,
                    icon: app.icon,
                    launchDate: app.launchDate,
                    isActive: app.processIdentifier == frontmostPID
                )
            }
            .sorted { lhs, rhs in
                if lhs.activationPolicy == .regular, rhs.activationPolicy != .regular {
                    return true
                }
                if lhs.activationPolicy != .regular, rhs.activationPolicy == .regular {
                    return false
                }
                return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
            }
        lastRefreshDate = Date()
    }
}
