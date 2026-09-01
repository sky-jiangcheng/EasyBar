import AppKit
import SwiftUI

@MainActor
final class StatusBarManager {
    private var statusItem: NSStatusItem?
    private let popover = NSPopover()
    private var eventMonitor: Any?
    private let aggregationPanel: AggregationPanel

    private let menuBarMonitor: MenuBarMonitor
    private let settingsStore: SettingsStore
    private let accessibilityManager: AccessibilityManager

    init(menuBarMonitor: MenuBarMonitor, settingsStore: SettingsStore, accessibilityManager: AccessibilityManager) {
        self.menuBarMonitor = menuBarMonitor
        self.settingsStore = settingsStore
        self.accessibilityManager = accessibilityManager
        self.aggregationPanel = AggregationPanel(
            menuBarMonitor: menuBarMonitor,
            settingsStore: settingsStore
        )

        setupStatusItem()
        setupPopover()
        setupEventMonitor()
    }

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        guard let button = statusItem?.button else { return }

        let icon = NSImage(systemSymbolName: "menubar.rectangle", accessibilityDescription: "EasyBar")
        button.image = icon
        button.toolTip = "EasyBar - Menu Bar Manager"

        button.action = #selector(statusBarButtonClicked(_:))
        button.target = self
    }

    private func setupPopover() {
        popover.contentSize = NSSize(width: 360, height: 400)
        popover.behavior = .transient
        popover.animates = true

        let hostingView = NSHostingView(
            rootView: PopoverView(
                onDismiss: { [weak self] in
                    self?.closePopover()
                }
            )
            .environment(menuBarMonitor)
            .environment(settingsStore)
            .environment(accessibilityManager)
        )

        popover.contentViewController = NSViewController()
        popover.contentViewController?.view = hostingView
    }

    private func setupEventMonitor() {
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) {
            [weak self] event in
            guard let self, self.popover.isShown else { return }
            if let window = event.window, window == self.statusItem?.button?.window {
                return
            }
            self.closePopover()
        }
    }

    @objc private func statusBarButtonClicked(_ sender: AnyObject?) {
        if popover.isShown {
            closePopover()
        } else {
            showPopover()
        }
    }

    private func showPopover() {
        guard let button = statusItem?.button else { return }
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func closePopover() {
        popover.performClose(nil)
    }
}
