import SwiftUI

struct ContentView: View {
    @Environment(MenuBarMonitor.self) private var menuBarMonitor
    @Environment(SettingsStore.self) private var settings
    @Environment(AccessibilityManager.self) private var accessibilityManager

    var body: some View {
        NavigationSplitView {
            sidebar
        } detail: {
            detailView
        }
        .frame(minWidth: 700, minHeight: 450)
    }

    private var sidebar: some View {
        List {
            Section("Menu Bar") {
                ForEach(menuBarMonitor.menuBarItems) { item in
                    HStack {
                        if let icon = item.icon {
                            Image(nsImage: icon)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 20, height: 20)
                        } else {
                            Image(systemName: "app.fill")
                                .frame(width: 20, height: 20)
                        }

                        VStack(alignment: .leading) {
                            Text(item.processName)
                                .font(.body)
                            Text(item.bundleIdentifier)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        if item.isHidden {
                            Image(systemName: "eye.slash")
                                .foregroundStyle(.orange)
                        }
                    }
                    .contextMenu {
                        Button(item.isHidden ? "Show" : "Hide") {
                            if item.isHidden {
                                menuBarMonitor.showItem(item)
                            } else {
                                menuBarMonitor.hideItem(item)
                            }
                        }
                    }
                }
            }
        }
        .listStyle(.sidebar)
    }

    private var detailView: some View {
        VStack(spacing: 20) {
            Image(systemName: "menubar.rectangle")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)

            Text("EasyBar")
                .font(.largeTitle)
                .fontWeight(.semibold)

            Text("Menu Bar Manager")
                .font(.title3)
                .foregroundStyle(.secondary)

            if !accessibilityManager.isAuthorized {
                Button("Grant Accessibility Permission") {
                    accessibilityManager.requestAuthorization()
                }
                .buttonStyle(.borderedProminent)
            } else {
                Text("Accessibility permission granted")
                    .foregroundStyle(.green)
            }

            Divider()

            HStack(spacing: 20) {
                StatCard(
                    title: "Total",
                    value: "\(menuBarMonitor.menuBarItems.count)",
                    icon: "list.bullet"
                )
                StatCard(
                    title: "Hidden",
                    value: "\(menuBarMonitor.menuBarItems.filter { $0.isHidden }.count)",
                    icon: "eye.slash"
                )
                StatCard(
                    title: "Visible",
                    value: "\(menuBarMonitor.menuBarItems.filter { !$0.isHidden }.count)",
                    icon: "eye"
                )
            }
        }
        .padding()
    }
}

private struct StatCard: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title)
                .fontWeight(.semibold)
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(width: 100)
        .padding()
        .background(.quaternary.opacity(0.3), in: RoundedRectangle(cornerRadius: 10))
    }
}
