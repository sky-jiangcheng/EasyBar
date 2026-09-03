import AppKit
import SwiftUI

@MainActor
final class AggregationPanel {
    private var panel: NSPanel?
    private let menuBarMonitor: MenuBarMonitor
    private let settingsStore: SettingsStore

    var isShown: Bool {
        panel?.isVisible ?? false
    }

    init(menuBarMonitor: MenuBarMonitor, settingsStore: SettingsStore) {
        self.menuBarMonitor = menuBarMonitor
        self.settingsStore = settingsStore
    }

    func show() {
        guard panel == nil else {
            panel?.orderFront(nil)
            return
        }

        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 360, height: 80),
            styleMask: [.nonactivatingPanel, .hudWindow, .utilityWindow],
            backing: .buffered,
            defer: false
        )

        panel.level = .statusBar
        panel.isFloatingPanel = true
        panel.hidesOnDeactivate = false
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.isMovableByWindowBackground = true
        panel.titlebarAppearsTransparent = true
        panel.titleVisibility = .hidden
        panel.backgroundColor = NSColor.windowBackgroundColor.withAlphaComponent(0.95)

        let hostingView = NSHostingView(
            rootView: AggregationView()
                .environment(menuBarMonitor)
                .environment(settingsStore)
        )

        panel.contentView = hostingView

        positionPanel(panel)

        panel.orderFront(nil)
        self.panel = panel
    }

    func hide() {
        panel?.orderOut(nil)
    }

    func toggle() {
        if isShown {
            hide()
        } else {
            show()
        }
    }

    func updatePosition() {
        guard let panel else { return }
        positionPanel(panel)
    }

    private func positionPanel(_ panel: NSPanel) {
        guard let screen = NSScreen.main else { return }

        let menuBarHeight = NSStatusBar.system.thickness
        let x = screen.frame.midX - panel.frame.width / 2
        let y = screen.frame.maxY - menuBarHeight - panel.frame.height - 4

        panel.setFrameOrigin(NSPoint(x: x, y: y))
    }
}
