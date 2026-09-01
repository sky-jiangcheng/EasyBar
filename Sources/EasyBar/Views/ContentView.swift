import AppKit
import SwiftUI

struct ContentView: View {
    @Environment(RunningAppsStore.self) private var runningAppsStore
    @Environment(ClockStore.self) private var clock
    @State private var selectedSection = DashboardLaunchOptions.initialSection
    @State private var searchText = DashboardLaunchOptions.initialSearchText
    @State private var showBackgroundApps = DashboardLaunchOptions.initialShowBackgroundApps

    private var filteredApps: [RunningAppInfo] {
        let source = showBackgroundApps ? runningAppsStore.apps : runningAppsStore.regularApps
        guard !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return source
        }

        return source.filter { app in
            app.name.localizedCaseInsensitiveContains(searchText)
                || app.bundleIdentifier.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationSplitView {
            SidebarView(
                selectedSection: $selectedSection,
                runningCount: runningAppsStore.regularApps.count,
                backgroundCount: runningAppsStore.backgroundApps.count
            )
        } detail: {
            VStack(spacing: 0) {
                HeaderView(
                    currentDate: clock.now,
                    visibleAppCount: filteredApps.count,
                    totalAppCount: showBackgroundApps ? runningAppsStore.apps.count : runningAppsStore.regularApps.count,
                    lastRefreshDate: runningAppsStore.lastRefreshDate
                )

                Divider()

                switch selectedSection {
                case .running:
                    RunningAppsView(
                        apps: filteredApps,
                        searchText: $searchText,
                        showBackgroundApps: $showBackgroundApps,
                        refresh: runningAppsStore.refresh
                    )
                case .shortcuts:
                    ShortcutsView()
                }
            }
            .navigationTitle("EasyBar")
            .toolbar {
                ToolbarItemGroup {
                    Button {
                        runningAppsStore.refresh()
                    } label: {
                        Label("Refresh", systemImage: "arrow.clockwise")
                    }
                    .keyboardShortcut("r", modifiers: [.command])

                    Button {
                        NSApp.hide(nil)
                    } label: {
                        Label("Hide", systemImage: "eye.slash")
                    }
                    .keyboardShortcut("h", modifiers: [.command, .shift])
                }
            }
        }
        .searchable(text: $searchText, placement: .toolbar, prompt: "Search apps")
    }
}

enum DashboardSection: String, CaseIterable, Identifiable {
    case running
    case shortcuts

    var id: String { rawValue }

    var title: String {
        switch self {
        case .running:
            return "Running Apps"
        case .shortcuts:
            return "Shortcuts"
        }
    }

    var systemImage: String {
        switch self {
        case .running:
            return "macwindow.on.rectangle"
        case .shortcuts:
            return "keyboard"
        }
    }
}
