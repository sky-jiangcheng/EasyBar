import AppKit
import SwiftUI

struct PopoverView: View {
    @Environment(MenuBarMonitor.self) private var menuBarMonitor
    @Environment(SettingsStore.self) private var settings

    @State private var searchText = ""

    let onDismiss: () -> Void

    private var allItems: [MenuBarMonitor.MenuBarItem] {
        menuBarMonitor.menuBarItems
    }

    private var filteredItems: [MenuBarMonitor.MenuBarItem] {
        guard !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return allItems
        }
        return allItems.filter { item in
            item.processName.localizedCaseInsensitiveContains(searchText)
                || item.bundleIdentifier.localizedCaseInsensitiveContains(searchText)
        }
    }

    private var statusItems: [MenuBarMonitor.MenuBarItem] {
        filteredItems.filter { $0.hasStatusBar }
    }

    private var backgroundItems: [MenuBarMonitor.MenuBarItem] {
        filteredItems.filter { $0.isBackground && !$0.hasStatusBar }
    }

    private var foregroundItems: [MenuBarMonitor.MenuBarItem] {
        filteredItems.filter { !$0.isBackground && !$0.hasStatusBar }
    }

    var body: some View {
        VStack(spacing: 0) {
            headerSection

            Divider()

            searchBar

            Divider()

            iconListSection

            Divider()

            footerSection
        }
        .frame(width: 360, height: 480)
    }

    private var headerSection: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Menu Bar Icons")
                    .font(.headline)
                Text("\(menuBarMonitor.menuBarItems.filter { $0.isHidden }.count) hidden")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            HStack(spacing: 6) {
                Image(systemName: "lock.shield")
                    .foregroundStyle(settings.aggregationMode == .aggregation ? .orange : .secondary)
                Text(settings.aggregationMode == .aggregation ? "Aggregation" : "Normal")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(.quaternary.opacity(0.6), in: Capsule())
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField("Search icons...", text: $searchText)
                .textFieldStyle(.plain)

            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.quaternary.opacity(0.4), in: RoundedRectangle(cornerRadius: 8))
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    private var iconListSection: some View {
        VStack(spacing: 0) {
            if filteredItems.isEmpty {
                ContentUnavailableView(
                    "No Icons",
                    systemImage: "menubar.rectangle",
                    description: Text("No menu bar icons found.")
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        if !statusItems.isEmpty {
                            sectionHeader(title: "Status Bar", icon: "menubar.rectangle", count: statusItems.count)
                            ForEach(statusItems) { item in
                                IconRow(item: item)
                            }
                        }

                        if !foregroundItems.isEmpty {
                            sectionHeader(title: "Foreground", icon: "macwindow", count: foregroundItems.count)
                            ForEach(foregroundItems) { item in
                                IconRow(item: item)
                            }
                        }

                        if !backgroundItems.isEmpty {
                            sectionHeader(title: "Background", icon: "后台运行", count: backgroundItems.count)
                            ForEach(backgroundItems) { item in
                                IconRow(item: item)
                            }
                        }
                    }
                }
            }
        }
    }

    private func sectionHeader(title: String, icon: String, count: Int) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text("(\(count))")
                .font(.caption2)
                .foregroundStyle(.tertiary)
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
        .background(.quaternary.opacity(0.3))
    }

    private var footerSection: some View {
        HStack {
            Text("EasyBar")
                .font(.caption)
                .foregroundStyle(.tertiary)

            Spacer()

            Button("Settings...") {
                if #available(macOS 14.0, *) {
                    NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
                } else {
                    NSApp.sendAction(Selector(("showSettingsWindow:")), to: NSApp, from: nil)
                }
            }
            .buttonStyle(.plain)
            .font(.caption)
            .foregroundStyle(.secondary)

            Button("Quit") {
                NSApp.terminate(nil)
            }
            .buttonStyle(.plain)
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
}

private struct IconRow: View {
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
                    .font(.system(.body, weight: .medium))
                    .lineLimit(1)
                    .foregroundStyle(.primary)
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

            Spacer()

            HStack(spacing: 8) {
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
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
        .contentShape(Rectangle())
        .background(item.isHidden ? Color.orange.opacity(0.05) : Color.clear)
    }
}
