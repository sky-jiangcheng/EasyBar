import Foundation

enum DashboardLaunchOptions {
    static var initialSearchText: String {
        ProcessInfo.processInfo.environment["EASYBAR_SEARCH"] ?? ""
    }

    static var initialShowBackgroundApps: Bool {
        let value = ProcessInfo.processInfo.environment["EASYBAR_SHOW_BACKGROUND"]?.lowercased()
        return value == "1" || value == "true" || value == "yes"
    }

    static var initialSection: DashboardSection {
        if ProcessInfo.processInfo.environment["EASYBAR_SECTION"] == "shortcuts" {
            return .shortcuts
        }
        return .running
    }
}
