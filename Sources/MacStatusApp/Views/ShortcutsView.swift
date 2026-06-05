import SwiftUI

struct ShortcutsView: View {
    private let shortcuts = [
        ShortcutInfo(keys: "Command R", action: "Refresh running apps"),
        ShortcutInfo(keys: "Command Shift H", action: "Hide MacStatus"),
        ShortcutInfo(keys: "Command F", action: "Search apps"),
        ShortcutInfo(keys: "Command W", action: "Close window")
    ]

    var body: some View {
        List(shortcuts) { shortcut in
            HStack(spacing: 16) {
                Text(shortcut.keys)
                    .font(.system(.body, design: .monospaced))
                    .frame(width: 150, alignment: .leading)
                Text(shortcut.action)
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .padding(.vertical, 8)
        }
        .listStyle(.inset(alternatesRowBackgrounds: true))
    }
}

private struct ShortcutInfo: Identifiable {
    let id = UUID()
    let keys: String
    let action: String
}
