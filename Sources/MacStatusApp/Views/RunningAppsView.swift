import AppKit
import SwiftUI

struct RunningAppsView: View {
    let apps: [RunningAppInfo]
    @Binding var searchText: String
    @Binding var showBackgroundApps: Bool
    let refresh: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Toggle("Show Background Apps", isOn: $showBackgroundApps)
                    .toggleStyle(.switch)

                Spacer()

                Button(action: refresh) {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 14)

            if apps.isEmpty {
                ContentUnavailableView(
                    "No Apps Found",
                    systemImage: "magnifyingglass",
                    description: Text("Try clearing the search field or showing background apps.")
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(apps) { app in
                    RunningAppRow(app: app)
                        .contextMenu {
                            Button("Copy Bundle Identifier") {
                                NSPasteboard.general.clearContents()
                                NSPasteboard.general.setString(app.displayBundleIdentifier, forType: .string)
                            }
                        }
                }
                .listStyle(.inset(alternatesRowBackgrounds: true))
            }
        }
    }
}

private struct RunningAppRow: View {
    let app: RunningAppInfo

    var body: some View {
        HStack(spacing: 12) {
            AppIconView(icon: app.icon)

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 8) {
                    Text(app.name)
                        .font(.headline)
                        .lineLimit(1)
                    if app.isActive {
                        Text("Active")
                            .font(.caption.weight(.medium))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.green.opacity(0.18), in: Capsule())
                    }
                }
                Text(app.displayBundleIdentifier)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 3) {
                Text(app.categoryName)
                    .font(.subheadline.weight(.medium))
                Text("PID \(app.processIdentifier)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
        }
        .padding(.vertical, 7)
    }
}

private struct AppIconView: View {
    let icon: NSImage?

    var body: some View {
        Group {
            if let icon {
                Image(nsImage: icon)
                    .resizable()
                    .scaledToFit()
            } else {
                Image(systemName: "app.dashed")
                    .font(.title2)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: 34, height: 34)
        .clipShape(RoundedRectangle(cornerRadius: 7))
    }
}
