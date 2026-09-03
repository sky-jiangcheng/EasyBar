import AppKit
import SwiftUI

struct PopoverView: View {
    @Environment(MenuBarMonitor.self) private var menuBarMonitor
    @Environment(SettingsStore.self) private var settings

    @State private var searchText = ""
    @State private var selectedFilter: FilterType = .all

    let onDismiss: () -> Void

    enum FilterType: String, CaseIterable {
        case all = "All"
        case hidden = "Hidden"
    }

    private var allItems: [MenuBarMonitor.MenuBarItem] {
        menuBarMonitor.menuBarItems
    }

    private var filteredItems: [MenuBarMonitor.MenuBarItem] {
        let items: [MenuBarMonitor.MenuBarItem]
        switch selectedFilter {
        case .all:
            items = allItems
        case .hidden:
            items = allItems.filter { $0.isHidden }
        }

        guard !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return items
        }
        return items.filter { item in
            item.processName.localizedCaseInsensitiveContains(searchText)
                || item.bundleIdentifier.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            headerSection

            Divider()

            filterBar

            Divider()

            iconListSection

            Divider()

            footerSection
        }
        .frame(width: 380, height: 500)
    }

    private var headerSection: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("EasyBar")
                    .font(.headline)
                Text("\(menuBarMonitor.menuBarItems.count) apps")
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

    private var filterBar: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Search...", text: $searchText)
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

            Picker("Filter", selection: $selectedFilter) {
                ForEach(FilterType.allCases, id: \.self) { filter in
                    Text(filter.rawValue).tag(filter)
                }
            }
            .pickerStyle(.segmented)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    private var iconListSection: some View {
        VStack(spacing: 0) {
            if filteredItems.isEmpty {
                ContentUnavailableView(
                    "No Apps",
                    systemImage: "app.badge",
                    description: Text("No apps found.")
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(filteredItems) { item in
                            IconRow(item: item)
                        }
                    }
                }
            }
        }
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

            HStack(spacing: 8) {
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
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .background(item.isHidden ? Color.orange.opacity(0.05) : Color.clear)
    }
}
