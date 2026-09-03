import SwiftUI

struct AggregationIconSelector: View {
    @Binding var selectedIcon: SettingsStore.AggregationIconType

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Aggregation Icon")
                .font(.headline)

            Text("Choose the icon displayed in the menu bar when aggregation mode is active.")
                .font(.caption)
                .foregroundStyle(.secondary)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 12) {
                ForEach(SettingsStore.AggregationIconType.allCases) { iconType in
                    IconOptionButton(
                        iconType: iconType,
                        isSelected: selectedIcon == iconType,
                        action: { selectedIcon = iconType }
                    )
                }
            }
        }
    }
}

private struct IconOptionButton: View {
    let iconType: SettingsStore.AggregationIconType
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                iconView
                    .frame(width: 44, height: 44)
                    .background(isSelected ? Color.accentColor.opacity(0.15) : Color.secondary.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay {
                        if isSelected {
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.accentColor, lineWidth: 2)
                        }
                    }

                Text(iconType.rawValue)
                    .font(.caption)
                    .foregroundStyle(isSelected ? .primary : .secondary)
            }
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var iconView: some View {
        switch iconType {
        case .dots:
            HStack(spacing: 4) {
                Circle().fill(Color.primary).frame(width: 6, height: 6)
                Circle().fill(Color.primary).frame(width: 6, height: 6)
                Circle().fill(Color.primary).frame(width: 6, height: 6)
            }
        case .grid:
            Image(systemName: "square.grid.2x2")
                .font(.title2)
        case .chevron:
            Image(systemName: "chevron.down")
                .font(.title2)
        case .square:
            Image(systemName: "square.fill")
                .font(.title2)
        case .circle:
            Image(systemName: "circle.fill")
                .font(.title2)
        case .transparent:
            Image(systemName: "circle.dotted")
                .font(.title2)
                .foregroundStyle(.secondary)
        }
    }
}
