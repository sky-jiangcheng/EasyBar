import SwiftUI

struct ContentView: View {
    @Environment(MenuBarMonitor.self) private var menuBarMonitor
    @Environment(SettingsStore.self) private var settings
    @Environment(AccessibilityManager.self) private var accessibilityManager

    @State private var selectedTab: SidebarTab = .all

    enum SidebarTab: String, CaseIterable {
        case all = "All Apps"
        case status = "Status Bar"
        case hidden = "Hidden"
    }

    var body: some View {
        NavigationSplitView {
            sidebar
        } detail: {
            detailView
        }
        .frame(minWidth: 800, minHeight: 500)
        .alert("Accessibility Permission Required", isPresented: Binding(
            get: { accessibilityManager.showPermissionAlert },
            set: { accessibilityManager.showPermissionAlert = $0 }
        )) {
            Button("Cancel") {
                accessibilityManager.showPermissionAlert = false
            }
            Button("Open Settings") {
                accessibilityManager.openAccessibilitySettings()
                accessibilityManager.showPermissionAlert = false
            }
        } message: {
            Text("EasyBar needs Accessibility permission to manage menu bar icons.")
        }
    }

    private var sidebar: some View {
        VStack(spacing: 0) {
            Picker("Filter", selection: $selectedTab) {
                ForEach(SidebarTab.allCases, id: \.self) { tab in
                    Text(tab.rawValue).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 12)
            .padding(.top, 12)
            .padding(.bottom, 8)

            List {
                switch selectedTab {
                case .all:
                    allAppsSection
                case .status:
                    statusAppsSection
                case .hidden:
                    hiddenAppsSection
                }
            }
            .listStyle(.sidebar)
        }
    }

    private var allAppsSection: some View {
        Group {
            if menuBarMonitor.menuBarItems.isEmpty {
                ContentUnavailableView(
                    "No Apps",
                    systemImage: "app.badge",
                    description: Text("No running apps detected.")
                )
            } else {
                ForEach(menuBarMonitor.menuBarItems) { item in
                    SidebarRow(item: item)
                }
            }
        }
    }

    private var statusAppsSection: some View {
        Group {
            let statusItems = menuBarMonitor.menuBarItems.filter { $0.hasStatusBar }
            if statusItems.isEmpty {
                ContentUnavailableView(
                    "No Status Bar Apps",
                    systemImage: "menubar.rectangle",
                    description: Text("No apps with status bar icons detected.")
                )
            } else {
                ForEach(statusItems) { item in
                    SidebarRow(item: item)
                }
            }
        }
    }

    private var hiddenAppsSection: some View {
        Group {
            let hiddenItems = menuBarMonitor.menuBarItems.filter { $0.isHidden }
            if hiddenItems.isEmpty {
                ContentUnavailableView(
                    "No Hidden Apps",
                    systemImage: "eye.slash",
                    description: Text("No apps are currently hidden.")
                )
            } else {
                ForEach(hiddenItems) { item in
                    SidebarRow(item: item)
                }
            }
        }
    }

    private var detailView: some View {
        VStack(spacing: 0) {
            headerView
            Divider()
            statsView
            Spacer()
        }
    }

    private var headerView: some View {
        VStack(spacing: 16) {
            Image(systemName: "menubar.rectangle")
                .font(.system(size: 48))
                .foregroundStyle(.blue)

            Text("EasyBar")
                .font(.largeTitle)
                .fontWeight(.semibold)

            Text("Menu Bar Manager")
                .font(.title3)
                .foregroundStyle(.secondary)

            if !accessibilityManager.isAuthorized {
                Button("Grant Accessibility Permission") {
                    accessibilityManager.requestAuthorization()
                }
                .buttonStyle(.borderedProminent)
            } else {
                Label("Accessibility granted", systemImage: "checkmark.shield.fill")
                    .foregroundStyle(.green)
            }
        }
        .padding(.top, 32)
        .padding(.bottom, 24)
    }

    private var statsView: some View {
        HStack(spacing: 16) {
            StatCard(
                title: "Total",
                value: "\(menuBarMonitor.menuBarItems.count)",
                icon: "list.bullet",
                color: .blue
            )
            StatCard(
                title: "Status Bar",
                value: "\(menuBarMonitor.menuBarItems.filter { $0.hasStatusBar }.count)",
                icon: "menubar.rectangle",
                color: .purple
            )
            StatCard(
                title: "Hidden",
                value: "\(menuBarMonitor.menuBarItems.filter { $0.isHidden }.count)",
                icon: "eye.slash",
                color: .orange
            )
            StatCard(
                title: "Running",
                value: "\(menuBarMonitor.menuBarItems.filter { !$0.isBackground }.count)",
                icon: "app.badge.checkmark",
                color: .green
            )
        }
        .padding(.horizontal, 32)
    }
}

private struct SidebarRow: View {
    @Environment(MenuBarMonitor.self) private var menuBarMonitor

    let item: MenuBarMonitor.MenuBarItem

    var body: some View {
        HStack(spacing: 10) {
            if let icon = item.icon {
                Image(nsImage: icon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            } else {
                Image(systemName: "app.fill")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .frame(width: 24, height: 24)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(item.processName)
                    .font(.body)
                    .lineLimit(1)

                HStack(spacing: 4) {
                    if item.hasStatusBar {
                        Label("Status", systemImage: "menubar.rectangle")
                            .font(.caption2)
                            .foregroundStyle(.blue)
                    }
                    if item.isBackground {
                        Label("BG", systemImage: "后台运行")
                            .font(.caption2)
                            .foregroundStyle(.purple)
                    }
                    Text(item.bundleIdentifier)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                }
            }

            Spacer()

            HStack(spacing: 6) {
                if item.isHidden {
                    Image(systemName: "eye.slash")
                        .font(.caption)
                        .foregroundStyle(.orange)
                        .help("Hidden - click to show")
                        .onTapGesture {
                            menuBarMonitor.showItem(item)
                        }
                } else {
                    Image(systemName: "eye")
                        .font(.caption)
                        .foregroundStyle(.green)
                        .help("Visible - click to hide")
                        .onTapGesture {
                            menuBarMonitor.hideItem(item)
                        }
                }

                Menu {
                    Button("Activate") {
                        menuBarMonitor.activateApp(item)
                    }
                    Button("Quit") {
                        menuBarMonitor.quitApp(item)
                    }
                    Divider()
                    Button("Force Quit", role: .destructive) {
                        menuBarMonitor.forceQuitApp(item)
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .menuStyle(.borderlessButton)
                .frame(width: 20)
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .background(item.isHidden ? Color.orange.opacity(0.05) : Color.clear)
    }
}

private struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            Text(value)
                .font(.title)
                .fontWeight(.semibold)
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(width: 120)
        .padding()
        .background(color.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
    }
}
