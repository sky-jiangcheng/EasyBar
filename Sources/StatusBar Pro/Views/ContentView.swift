import SwiftUI

struct ContentView: View {
    @Environment(MenuBarMonitor.self) private var menuBarMonitor
    @Environment(SettingsStore.self) private var settings
    @Environment(AccessibilityManager.self) private var accessibilityManager

    @State private var selectedFilter: AppFilter = .all

    enum AppFilter: String, CaseIterable {
        case all, statusbar, dock
    }

    private var l10n: L10nTable { settings.l10n }

    private var filteredItems: [MenuBarMonitor.MenuBarItem] {
        let base = menuBarMonitor.sortedByCustomOrder(menuBarMonitor.menuBarItems)
        switch selectedFilter {
        case .all:
            return base
        case .statusbar:
            return base.filter { $0.appType == .statusbarOnly }
        case .dock:
            return base.filter { $0.appType == .dockOnly }
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
        .onAppear {
            accessibilityManager.refresh()
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
            Picker(l10n.all, selection: $selectedFilter) {
                Text(l10n.all).tag(AppFilter.all)
                Text(l10n.statusBar).tag(AppFilter.statusbar)
                Text(l10n.dock).tag(AppFilter.dock)
            }
            .pickerStyle(.segmented)

            Text(String(format: l10n.appsCount, filteredItems.count))
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
                    l10n.noApps,
                    systemImage: "app.badge",
                    description: Text(selectedFilter == .all ? l10n.noAppsFound : l10n.noAppsInCategory)
                )
            } else {
                ForEach(filteredItems) { item in
                    SidebarRow(item: item, l10n: l10n)
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

                Text(l10n.menuBarManager)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Diagnostic only — the app never requests Accessibility access, so
            // this is a passive label instead of a permission prompt.
            if accessibilityManager.isAuthorized {
                Label(l10n.granted, systemImage: "checkmark.shield.fill")
                    .font(.caption)
                    .foregroundStyle(.green)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.green.opacity(0.1), in: Capsule())
            } else {
                Label(l10n.accessibilityOptional, systemImage: "info.circle")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.quaternary.opacity(0.6), in: Capsule())
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 20)
    }

    private var statsView: some View {
        HStack(spacing: 12) {
            StatCard(
                title: l10n.total,
                value: "\(menuBarMonitor.menuBarItems.count)",
                icon: "list.bullet",
                color: .blue,
                isSelected: selectedFilter == .all
            ) {
                withAnimation { selectedFilter = .all }
            }

            StatCard(
                title: l10n.statusBar,
                value: "\(menuBarMonitor.menuBarItems.filter { $0.appType == .statusbarOnly }.count)",
                icon: "menubar.rectangle",
                color: .purple,
                isSelected: selectedFilter == .statusbar
            ) {
                withAnimation { selectedFilter = .statusbar }
            }

            StatCard(
                title: l10n.dock,
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
    let l10n: L10nTable

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

                Text(item.appType == .statusbarOnly ? l10n.statusBar : l10n.dock)
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
                .help(l10n.open)

#if !MAC_APP_STORE
                Button {
                    menuBarMonitor.quitApp(item)
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.body)
                        .foregroundStyle(.red)
                }
                .buttonStyle(.plain)
                .help(l10n.quit)

                Button {
                    menuBarMonitor.forceQuitApp(item)
                } label: {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
                .buttonStyle(.plain)
                .help(l10n.forceQuit)
#endif
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
