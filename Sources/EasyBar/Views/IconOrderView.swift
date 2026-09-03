import SwiftUI

struct IconOrderView: View {
    @Binding var customOrder: [String]
    let menuBarItems: [MenuBarMonitor.MenuBarItem]

    var orderedItems: [MenuBarMonitor.MenuBarItem] {
        let itemMap = Dictionary(uniqueKeysWithValues: menuBarItems.map { ($0.id, $0) })
        return customOrder.compactMap { itemMap[$0] }
    }

    var unorderedItems: [MenuBarMonitor.MenuBarItem] {
        let orderSet = Set(customOrder)
        return menuBarItems.filter { !orderSet.contains($0.id) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Icon Order")
                .font(.headline)

            Text("Drag to reorder icons. Icons not in the list will appear after custom-ordered icons.")
                .font(.caption)
                .foregroundStyle(.secondary)

            if orderedItems.isEmpty && unorderedItems.isEmpty {
                ContentUnavailableView(
                    "No Icons",
                    systemImage: "list.bullet",
                    description: Text("No menu bar icons detected.")
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    if !orderedItems.isEmpty {
                        Section("Custom Order") {
                            ForEach(orderedItems) { item in
                                IconRow(item: item)
                            }
                            .onMove { source, destination in
                                customOrder.move(fromOffsets: source, toOffset: destination)
                            }
                            .onDelete { indexSet in
                                for index in indexSet {
                                    let itemID = orderedItems[index].id
                                    customOrder.removeAll { $0 == itemID }
                                }
                            }
                        }
                    }

                    if !unorderedItems.isEmpty {
                        Section("Unordered") {
                            ForEach(unorderedItems) { item in
                                IconRow(item: item)
                                    .draggable(item.id)
                            }
                        }
                    }
                }
                .listStyle(.inset(alternatesRowBackgrounds: true))
            }
        }
    }
}

private struct IconRow: View {
    let item: MenuBarMonitor.MenuBarItem

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "line.3.horizontal")
                .foregroundStyle(.secondary)

            if let icon = item.icon {
                Image(nsImage: icon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
            } else {
                Image(systemName: "app.fill")
                    .foregroundStyle(.secondary)
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
        .padding(.vertical, 4)
    }
}
