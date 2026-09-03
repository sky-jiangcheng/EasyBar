import SwiftUI

struct ContentView: View {
    @Environment(MenuBarMonitor.self) private var menuBarMonitor
    @Environment(SettingsStore.self) private var settings
    @Environment(AccessibilityManager.self) private var accessibilityManager

    @State private var selectedFilter: AppFilter = .all

    enum AppFilter: String, CaseIterable {
        case all = "All"
        case statusbar = "Status Bar"
        case dock = "Dock"
    }

    private var filteredItems: [MenuBarMonitor.MenuBarItem] {
        switch selectedFilter {
        case .all:
            menuBarMonitor.menuBarItems
        case .statusbar:
            menuBarMonitor.menuBarItems.filter { $0.appType == .statusbarOnly }
        case .dock:
            menuBarMonitor.menuBarItems.filter { $0.appType == .dockOnly }
        }
    }

    var body: some View {
        HSplitView {
            sidebar
                .frame(minWidth: 260, idealWidth: 300, maxWidth: 360)

            detailView
                .frame(minWidth: 400, idealWidth: 500)
        }
        .frame(minWidth: 700, minHeight: 500)
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
            Text("StatusBar Pro needs Accessibility permission to manage menu bar icons.")
        }
    }

    private var sidebar: some View {
        VStack(spacing: 0) {
            sidebarHeader
            Divider()
            sidebarList
        }
    }

    private var sidebarHeader: some View {
        VStack(spacing: 8) {
            Picker("Filter", selection: $selectedFilter) {
                ForEach(AppFilter.allCases, id: \.self) { filter in
                    Text(filter.rawValue).tag(filter)
                }
            }
            .pickerStyle(.segmented)

            Text("\(filteredItems.count) apps")
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    private var sidebarList: some View {
        List {
            if filteredItems.isEmpty {
                ContentUnavailableView(
                    "No Apps",
                    systemImage: "app.badge",
                    description: Text("No apps in this category.")
                )
            } else {
                ForEach(filteredItems) { item in
                    SidebarRow(item: item)
                }
            }
        }
        .listStyle(.sidebar)
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
        HStack(spacing: 12) {
            Image(systemName: "menubar.rectangle")
                .font(.system(size: 36))
                .foregroundStyle(.blue)

            VStack(alignment: .leading, spacing: 2) {
                Text("StatusBar Pro")
                    .font(.title)
                    .fontWeight(.semibold)

                Text("Menu Bar Manager")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if !accessibilityManager.isAuthorized {
                Button("Grant Permission") {
                    accessibilityManager.requestAuthorization()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            } else {
                Label("Granted", systemImage: "checkmark.shield.fill")
                    .font(.caption)
                    .foregroundStyle(.green)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.green.opacity(0.1), in: Capsule())
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 20)
    }

    private var statsView: some View {
        HStack(spacing: 12) {
            StatCard(
                title: "Total",
                value: "\(menuBarMonitor.menuBarItems.count)",
                icon: "list.bullet",
                color: .blue,
                isSelected: selectedFilter == .all
            ) {
                withAnimation { selectedFilter = .all }
            }

            StatCard(
                title: "Status Bar",
                value: "\(menuBarMonitor.menuBarItems.filter { $0.appType == .statusbarOnly }.count)",
                icon: "menubar.rectangle",
                color: .purple,
                isSelected: selectedFilter == .statusbar
            ) {
                withAnimation { selectedFilter = .statusbar }
            }

            StatCard(
                title: "Dock",
                value: "\(menuBarMonitor.menuBarItems.filter { $0.appType == .dockOnly }.count)",
                icon: "dock.rectangle",
                color: .green,
                isSelected: selectedFilter == .dock
            ) {
                withAnimation { selectedFilter = .dock }
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
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
                    .frame(width: 28, height: 28)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            } else {
                Image(systemName: "app.fill")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .frame(width: 28, height: 28)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(item.processName)
                    .font(.body)
                    .lineLimit(1)

                Text(item.appType == .statusbarOnly ? "Status Bar" : "Dock")
                    .font(.caption)
                    .foregroundStyle(item.appType == .statusbarOnly ? .purple : .green)
            }

            Spacer()

            HStack(spacing: 8) {
                Button {
                    menuBarMonitor.activateApp(item)
                } label: {
                    Image(systemName: "arrow.up.forward.app")
                        .font(.body)
                        .foregroundStyle(.blue)
                }
                .buttonStyle(.plain)
                .help("Open")

                Button {
                    menuBarMonitor.quitApp(item)
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.body)
                        .foregroundStyle(.red)
                }
                .buttonStyle(.plain)
                .help("Quit")

                Button {
                    menuBarMonitor.forceQuitApp(item)
                } label: {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
                .buttonStyle(.plain)
                .help("Force Quit")
            }
        }
        .padding(.vertical, 6)
        .contentShape(Rectangle())
    }
}

private struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(isSelected ? .white : color)
                Text(value)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(isSelected ? .white : .primary)
                Text(title)
                    .font(.caption)
                    .foregroundStyle(isSelected ? .white.opacity(0.8) : .secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? color : color.opacity(0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? color : .clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }
}
