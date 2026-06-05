import SwiftUI

struct SidebarView: View {
    @Binding var selectedSection: DashboardSection
    let runningCount: Int
    let backgroundCount: Int

    var body: some View {
        List(selection: $selectedSection) {
            Section("Dashboard") {
                Label {
                    Text("Running Apps")
                } icon: {
                    Image(systemName: "macwindow.on.rectangle")
                }
                .tag(DashboardSection.running)

                Label {
                    Text("Shortcuts")
                } icon: {
                    Image(systemName: "keyboard")
                }
                .tag(DashboardSection.shortcuts)
            }

            Section("Summary") {
                SummaryRow(title: "Visible Apps", value: runningCount.formatted())
                SummaryRow(title: "Background", value: backgroundCount.formatted())
            }
        }
        .listStyle(.sidebar)
        .navigationTitle("MacStatus")
    }
}

private struct SummaryRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
                .foregroundStyle(.secondary)
                .monospacedDigit()
        }
    }
}
