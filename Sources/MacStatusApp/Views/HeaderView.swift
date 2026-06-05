import SwiftUI

struct HeaderView: View {
    let currentDate: Date
    let visibleAppCount: Int
    let totalAppCount: Int
    let lastRefreshDate: Date

    var body: some View {
        HStack(alignment: .center, spacing: 18) {
            VStack(alignment: .leading, spacing: 4) {
                Text(DashboardFormatters.time.string(from: currentDate))
                    .font(.system(size: 44, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                Text(DashboardFormatters.date.string(from: currentDate))
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            MetricTile(title: "Apps", value: "\(visibleAppCount)", subtitle: "\(totalAppCount) tracked")
            MetricTile(
                title: "Updated",
                value: DashboardFormatters.refresh.localizedString(for: lastRefreshDate, relativeTo: currentDate),
                subtitle: "Cmd-R"
            )
        }
        .padding(24)
    }
}

private struct MetricTile: View {
    let title: String
    let value: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title3.weight(.semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(width: 116, alignment: .leading)
        .padding(12)
        .background(.quaternary.opacity(0.55), in: RoundedRectangle(cornerRadius: 8))
    }
}
