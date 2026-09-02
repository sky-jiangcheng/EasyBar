import SwiftUI

struct AggregationView: View {
    @Environment(MenuBarMonitor.self) private var menuBarMonitor
    @Environment(SettingsStore.self) private var settings

    let onShowTemporarily: (MenuBarMonitor.MenuBarItem) -> Void
    let onHidePermanently: (MenuBarMonitor.MenuBarItem) -> Void

    private var hiddenItems: [MenuBarMonitor.MenuBarItem] {
        menuBarMonitor.menuBarItems.filter { $0.isHidden }
    }

    var body: some View {
        VStack(spacing: 0) {
            if hiddenItems.isEmpty {
                emptyState
            } else {
                iconGrid
            }
        }
        .frame(width: 360, height: 80)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    private var emptyState: some View {
        HStack {
            aggregationIconView
                .frame(width: 20, height: 20)
            Text("No hidden icons")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var iconGrid: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: settings.iconSpacing.value) {
                ForEach(hiddenItems) { item in
                    IconButton(
                        item: item,
                        onTap: { onShowTemporarily(item) },
                        onHide: { onHidePermanently(item) }
                    )
                }
            }
        }
    }

    @ViewBuilder
    private var aggregationIconView: some View {
        switch settings.aggregationIcon {
        case .dots:
            HStack(spacing: 3) {
                Circle().fill(Color.primary).frame(width: 5, height: 5)
                Circle().fill(Color.primary).frame(width: 5, height: 5)
                Circle().fill(Color.primary).frame(width: 5, height: 5)
            }
        case .grid:
            Image(systemName: "square.grid.2x2")
        case .chevron:
            Image(systemName: "chevron.down")
        case .square:
            Image(systemName: "square.fill")
        case .circle:
            Image(systemName: "circle.fill")
        case .transparent:
            Image(systemName: "circle.dotted")
                .foregroundStyle(.secondary)
        }
    }
}

private struct IconButton: View {
    let item: MenuBarMonitor.MenuBarItem
    let onTap: () -> Void
    let onHide: () -> Void

    @State private var isHovering = false

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                if let icon = item.icon {
                    Image(nsImage: icon)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                } else {
                    Image(systemName: "app.fill")
                        .font(.title3)
                        .frame(width: 24, height: 24)
                }

                Text(item.processName)
                    .font(.system(size: 9))
                    .lineLimit(1)
            }
            .frame(width: 56, height: 56)
            .background(.quaternary.opacity(0.6), in: RoundedRectangle(cornerRadius: 8))
            .overlay {
                if isHovering {
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(.secondary, lineWidth: 1)
                }
            }
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovering = hovering
        }
        .help("Click to show temporarily\nRight-click to hide permanently")
        .contextMenu {
            Button("Hide Permanently") {
                onHide()
            }
        }
    }
}
