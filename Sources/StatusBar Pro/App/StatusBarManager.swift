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
        setupNotifications()
    }

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        guard let button = statusItem?.button else { return }

        let icon = NSImage(systemSymbolName: "menubar.rectangle", accessibilityDescription: "StatusBar Pro")
        button.image = icon
        button.toolTip = "StatusBar Pro - Menu Bar Manager"

        button.action = #selector(statusBarButtonClicked(_:))
        button.target = self
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])
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

    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            forName: .aggregationShouldShow,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                guard let self, self.settingsStore.aggregationMode == .aggregation else { return }
                if !self.aggregationPanel.isShown {
                    self.aggregationPanel.show()
                }
            }
        }
    }

    @objc private func statusBarButtonClicked(_ sender: AnyObject?) {
        guard let event = NSApp.currentEvent else { return }

        if event.type == .rightMouseUp {
            showContextMenu()
        } else {
            if popover.isShown {
                closePopover()
            } else {
                showPopover()
            }
        }
    }

    private func showContextMenu() {
        let menu = NSMenu()

        let panelItem = NSMenuItem(
            title: aggregationPanel.isShown ? "Hide Aggregation Panel" : "Show Aggregation Panel",
            action: #selector(toggleAggregationPanel),
            keyEquivalent: ""
        )
        panelItem.target = self
        menu.addItem(panelItem)

        menu.addItem(.separator())

        let settingsItem = NSMenuItem(
            title: "Settings...",
            action: #selector(openSettings),
            keyEquivalent: ","
        )
        settingsItem.target = self
        menu.addItem(settingsItem)

        menu.addItem(.separator())

        let quitItem = NSMenuItem(
            title: "Quit StatusBar Pro",
            action: #selector(quitApp),
            keyEquivalent: "q"
        )
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem?.menu = menu
        statusItem?.button?.performClick(nil)
        statusItem?.menu = nil
    }

    @objc private func toggleAggregationPanel() {
        aggregationPanel.toggle()
    }

    @objc private func openSettings() {
        if #available(macOS 14.0, *) {
            NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
        } else {
            NSApp.sendAction(Selector(("showSettingsWindow:")), to: NSApp, from: nil)
        }
    }

    @objc private func quitApp() {
        NSApp.terminate(nil)
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
