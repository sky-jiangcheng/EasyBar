import SwiftUI

struct AggregationView: View {
    @Environment(MenuBarMonitor.self) private var menuBarMonitor
    @Environment(SettingsStore.self) private var settings

    var body: some View {
        VStack(spacing: 0) {
            if menuBarMonitor.menuBarItems.isEmpty {
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
            Text("No apps running")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var iconGrid: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: settings.iconSpacing.value) {
                ForEach(menuBarMonitor.menuBarItems) { item in
                    AggregationIcon(item: item)
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

private struct AggregationIcon: View {
    let item: MenuBarMonitor.MenuBarItem

    @State private var isHovering = false

    var body: some View {
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
        .onHover { hovering in
            isHovering = hovering
        }
        .help(item.processName)
    }
}
