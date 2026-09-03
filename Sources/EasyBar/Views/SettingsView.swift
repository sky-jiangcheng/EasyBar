import SwiftUI

struct SettingsView: View {
    @Environment(SettingsStore.self) private var settings
    @Environment(MenuBarMonitor.self) private var menuBarMonitor

    var body: some View {
        TabView {
            GeneralSettingsTab(
                aggregationMode: Binding(
                    get: { settings.aggregationMode },
                    set: { settings.aggregationMode = $0; settings.save() }
                ),
                refreshInterval: Binding(
                    get: { settings.refreshInterval },
                    set: {
                        settings.refreshInterval = $0
                        settings.save()
                        NotificationCenter.default.post(name: .refreshIntervalChanged, object: nil)
                    }
                )
            )
            .tabItem {
                Label("General", systemImage: "gear")
            }

            AggregationSettingsTab(
                aggregationIcon: Binding(
                    get: { settings.aggregationIcon },
                    set: { settings.aggregationIcon = $0; settings.save() }
                ),
                autoHideDelay: Binding(
                    get: { settings.autoHideDelay },
                    set: { settings.autoHideDelay = $0; settings.save() }
                )
            )
            .tabItem {
                Label("Aggregation", systemImage: "rectangle.stack")
            }

            IconManagementTab()
                .tabItem {
                    Label("Icons", systemImage: "list.bullet")
                }

            IconOrderTab(
                customOrder: Binding(
                    get: { settings.customOrder },
                    set: { settings.customOrder = $0; settings.save() }
                )
            )
            .tabItem {
                Label("Order", systemImage: "arrow.up.arrow.down")
            }
        }
        .formStyle(.grouped)
    }
}

struct GeneralSettingsTab: View {
    @Binding var aggregationMode: SettingsStore.AggregationMode
    @Binding var refreshInterval: TimeInterval

    var body: some View {
        Form {
            Section("Mode") {
                Picker("Operating Mode", selection: $aggregationMode) {
                    ForEach(SettingsStore.AggregationMode.allCases, id: \.self) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)

                Text(modeDescription)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Refresh") {
                HStack {
                    Text("Menu bar scan interval")
                    Spacer()
                    Picker("", selection: $refreshInterval) {
                        Text("1s").tag(1.0)
                        Text("2s").tag(2.0)
                        Text("5s").tag(5.0)
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 160)
                }
            }
        }
    }

    private var modeDescription: String {
        switch aggregationMode {
        case .aggregation:
            return "Hide menu bar icons and display them in a floating aggregation panel below the menu bar."
        case .normal:
            return "Fold menu bar icons into a single expandable menu item."
        case .disabled:
            return "EasyBar will not manage menu bar icons."
        }
    }
}

struct AggregationSettingsTab: View {
    @Binding var aggregationIcon: SettingsStore.AggregationIconType
    @Binding var autoHideDelay: TimeInterval?

    var body: some View {
        Form {
            Section("Aggregation Icon") {
                AggregationIconSelector(selectedIcon: $aggregationIcon)
            }

            Section("Auto Hide") {
                HStack {
                    Text("Delay before hiding")
                    Spacer()
                    Picker("", selection: $autoHideDelay) {
                        Text("2s").tag(TimeInterval?(2.0))
                        Text("5s").tag(TimeInterval?(5.0))
                        Text("10s").tag(TimeInterval?(10.0))
                        Text("30s").tag(TimeInterval?(30.0))
                        Text("Never").tag(TimeInterval?(nil) as TimeInterval?)
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 280)
                }

                Text("How long to keep a temporarily shown icon before hiding it again.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

struct IconManagementTab: View {
    @Environment(SettingsStore.self) private var settings
    @Environment(MenuBarMonitor.self) private var menuBarMonitor

    var body: some View {
        Form {
            Section("Menu Bar Icons") {
                Text("Detected apps and their type.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                List(menuBarMonitor.menuBarItems) { item in
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

                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.processName)
                                .font(.body)
                            Text(item.bundleIdentifier)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Text(item.appType == .statusbarOnly ? "Status Bar" : "Dock")
                            .font(.caption)
                            .foregroundStyle(item.appType == .statusbarOnly ? .purple : .green)
                    }
                }
                .listStyle(.inset(alternatesRowBackgrounds: true))
                .frame(height: 280)
            }
        }
    }
}

struct IconOrderTab: View {
    @Binding var customOrder: [String]
    @Environment(MenuBarMonitor.self) private var menuBarMonitor

    var body: some View {
        Form {
            IconOrderView(
                customOrder: $customOrder,
                menuBarItems: menuBarMonitor.menuBarItems
            )
        }
    }
}
