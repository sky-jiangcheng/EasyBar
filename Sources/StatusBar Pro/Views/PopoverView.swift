import AppKit
import SwiftUI

struct PopoverView: View {
    @Environment(MenuBarMonitor.self) private var menuBarMonitor
    @Environment(SettingsStore.self) private var settings

    @State private var searchText = ""

    let onDismiss: () -> Void

    private var filteredItems: [MenuBarMonitor.MenuBarItem] {
        guard !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return menuBarMonitor.menuBarItems
        }
        return menuBarMonitor.menuBarItems.filter { item in
            item.processName.localizedCaseInsensitiveContains(searchText)
                || item.bundleIdentifier.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            headerSection

            Divider()

            searchSection

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
                Text("StatusBar Pro")
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

    private var searchSection: some View {
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
            Text("StatusBar Pro")
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
                Text(item.appType == .statusbarOnly ? "Status Bar" : "Dock")
                    .font(.caption2)
                    .foregroundStyle(item.appType == .statusbarOnly ? .purple : .green)
            }

            Spacer()

            HStack(spacing: 8) {
                Button {
                    menuBarMonitor.activateApp(item)
                } label: {
                    Image(systemName: "arrow.up.forward.app")
                        .font(.caption)
                        .foregroundStyle(.blue)
                }
                .buttonStyle(.plain)
                .help("Open")

#if !MAC_APP_STORE
                Button {
                    menuBarMonitor.quitApp(item)
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.red)
                }
                .buttonStyle(.plain)
                .help("Quit")

                Button {
                    menuBarMonitor.forceQuitApp(item)
                } label: {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                }
                .buttonStyle(.plain)
                .help("Force Quit")
#endif
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .contentShape(Rectangle())
    }
}
