import SwiftUI

struct ContentView: View {
    @Environment(MenuBarMonitor.self) private var menuBarMonitor
    @Environment(SettingsStore.self) private var settings
    @Environment(AccessibilityManager.self) private var accessibilityManager

    @State private var selectedTab: SidebarTab = .all

    enum SidebarTab: String, CaseIterable {
        case all = "All"
        case status = "Status Bar"
        case hidden = "Hidden"
    }

    private var filteredItems: [MenuBarMonitor.MenuBarItem] {
        switch selectedTab {
        case .all:
            menuBarMonitor.menuBarItems
        case .status:
            menuBarMonitor.menuBarItems.filter { $0.hasStatusBar }
        case .hidden:
            menuBarMonitor.menuBarItems.filter { $0.isHidden }
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
            Text("EasyBar needs Accessibility permission to manage menu bar icons.")
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
            Picker("Filter", selection: $selectedTab) {
                ForEach(SidebarTab.allCases, id: \.self) { tab in
                    Text(tab.rawValue).tag(tab)
                }
            }
            .pickerStyle(.segmented)

            HStack {
                Text("\(filteredItems.count) apps")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                if !menuBarMonitor.menuBarItems.filter({ $0.isHidden }).isEmpty {
                    Text("\(menuBarMonitor.menuBarItems.filter({ $0.isHidden }).count) hidden")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    private var sidebarList: some View {
        List {
            if filteredItems.isEmpty {
                ContentUnavailableView(
                    emptyTitle,
                    systemImage: emptyIcon,
                    description: Text(emptyDescription)
                )
            } else {
                ForEach(filteredItems) { item in
                    SidebarRow(item: item)
                }
            }
        }
        .listStyle(.sidebar)
    }

    private var emptyTitle: String {
        switch selectedTab {
        case .all: return "No Apps"
        case .status: return "No Status Bar Apps"
        case .hidden: return "No Hidden Apps"
        }
    }

    private var emptyIcon: String {
        switch selectedTab {
        case .all: return "app.badge"
        case .status: return "menubar.rectangle"
        case .hidden: return "eye.slash"
        }
    }

    private var emptyDescription: String {
        switch selectedTab {
        case .all: return "No running apps detected."
        case .status: return "No apps with status bar icons."
        case .hidden: return "No apps are currently hidden."
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
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: "menubar.rectangle")
                    .font(.system(size: 36))
                    .foregroundStyle(.blue)

                VStack(alignment: .leading, spacing: 2) {
                    Text("EasyBar")
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
                isSelected: selectedTab == .all
            ) {
                withAnimation { selectedTab = .all }
            }

            StatCard(
                title: "Status Bar",
                value: "\(menuBarMonitor.menuBarItems.filter { $0.hasStatusBar }.count)",
                icon: "menubar.rectangle",
                color: .purple,
                isSelected: selectedTab == .status
            ) {
                withAnimation { selectedTab = .status }
            }

            StatCard(
                title: "Hidden",
                value: "\(menuBarMonitor.menuBarItems.filter { $0.isHidden }.count)",
                icon: "eye.slash",
                color: .orange,
                isSelected: selectedTab == .hidden
            ) {
                withAnimation { selectedTab = .hidden }
            }

            StatCard(
                title: "Background",
                value: "\(menuBarMonitor.menuBarItems.filter { $0.isBackground }.count)",
                icon: "后台运行",
                color: .secondary,
                isSelected: false
            ) {
                withAnimation { selectedTab = .all }
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
        HStack(spacing: 8) {
            if let icon = item.icon {
                Image(nsImage: icon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 22, height: 22)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            } else {
                Image(systemName: "app.fill")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .frame(width: 22, height: 22)
            }

            VStack(alignment: .leading, spacing: 1) {
                Text(item.processName)
                    .font(.callout)
                    .lineLimit(1)

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
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 4)

            HStack(spacing: 4) {
                Button {
                    if item.isHidden {
                        menuBarMonitor.showItem(item)
                    } else {
                        menuBarMonitor.hideItem(item)
                    }
                } label: {
                    Image(systemName: item.isHidden ? "eye.slash" : "eye")
                        .font(.caption)
                        .foregroundStyle(item.isHidden ? .orange : .green)
                }
                .buttonStyle(.plain)
                .help(item.isHidden ? "Show" : "Hide")

                Menu {
                    Button("Activate") { menuBarMonitor.activateApp(item) }
                    Button("Quit") { menuBarMonitor.quitApp(item) }
                    Divider()
                    Button("Force Quit", role: .destructive) { menuBarMonitor.forceQuitApp(item) }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .menuStyle(.borderlessButton)
                .frame(width: 16)
            }
        }
        .padding(.vertical, 3)
        .contentShape(Rectangle())
        .background(item.isHidden ? Color.orange.opacity(0.05) : Color.clear)
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
