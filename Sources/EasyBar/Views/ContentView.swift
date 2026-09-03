import SwiftUI

struct ContentView: View {
    @Environment(MenuBarMonitor.self) private var menuBarMonitor
    @Environment(SettingsStore.self) private var settings
    @Environment(AccessibilityManager.self) private var accessibilityManager

    var body: some View {
        NavigationSplitView {
            sidebar
        } detail: {
            detailView
        }
        .frame(minWidth: 700, minHeight: 450)
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
        List {
            Section("Status Bar Apps") {
                ForEach(menuBarMonitor.menuBarItems.filter { $0.hasStatusBar }) { item in
                    SidebarRow(item: item)
                }
            }

            Section("Foreground Apps") {
                ForEach(menuBarMonitor.menuBarItems.filter { !$0.hasStatusBar && !$0.isBackground }) { item in
                    SidebarRow(item: item)
                }
            }

            Section("Background Apps") {
                ForEach(menuBarMonitor.menuBarItems.filter { $0.isBackground }) { item in
                    SidebarRow(item: item)
                }
            }
        }
        .listStyle(.sidebar)
    }

    private var detailView: some View {
        VStack(spacing: 20) {
            Image(systemName: "menubar.rectangle")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)

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
                Text("Accessibility permission granted")
                    .foregroundStyle(.green)
            }

            Divider()

            HStack(spacing: 20) {
                StatCard(
                    title: "Total",
                    value: "\(menuBarMonitor.menuBarItems.count)",
                    icon: "list.bullet"
                )
                StatCard(
                    title: "Status Bar",
                    value: "\(menuBarMonitor.menuBarItems.filter { $0.hasStatusBar }.count)",
                    icon: "menubar.rectangle"
                )
                StatCard(
                    title: "Foreground",
                    value: "\(menuBarMonitor.menuBarItems.filter { !$0.hasStatusBar && !$0.isBackground }.count)",
                    icon: "macwindow"
                )
                StatCard(
                    title: "Background",
                    value: "\(menuBarMonitor.menuBarItems.filter { $0.isBackground }.count)",
                    icon: "后台运行"
                )
                StatCard(
                    title: "Hidden",
                    value: "\(menuBarMonitor.menuBarItems.filter { $0.isHidden }.count)",
                    icon: "eye.slash"
                )
            }
        }
        .padding()
    }
}

private struct SidebarRow: View {
    @Environment(MenuBarMonitor.self) private var menuBarMonitor

    let item: MenuBarMonitor.MenuBarItem

    var body: some View {
        HStack {
            if let icon = item.icon {
                Image(nsImage: icon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
            } else {
                Image(systemName: "app.fill")
                    .frame(width: 20, height: 20)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(item.processName)
                    .font(.body)
                HStack(spacing: 4) {
                    if item.hasStatusBar {
                        Image(systemName: "menubar.rectangle")
                            .font(.caption2)
                            .foregroundStyle(.blue)
                    }
                    if item.isBackground {
                        Image(systemName: "后台运行")
                            .font(.caption2)
                            .foregroundStyle(.purple)
                    }
                    Text(item.bundleIdentifier)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            if item.isHidden {
                Image(systemName: "eye.slash")
                    .foregroundStyle(.orange)
            }
        }
        .contextMenu {
            Button(item.isHidden ? "Show" : "Hide") {
                if item.isHidden {
                    menuBarMonitor.showItem(item)
                } else {
                    menuBarMonitor.hideItem(item)
                }
            }
            Divider()
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
        }
    }
}

private struct StatCard: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title)
                .fontWeight(.semibold)
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(width: 100)
        .padding()
        .background(.quaternary.opacity(0.3), in: RoundedRectangle(cornerRadius: 10))
    }
}
