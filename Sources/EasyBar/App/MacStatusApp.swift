import AppKit
import SwiftUI

@main
struct EasyBarApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @State private var runningAppsStore = RunningAppsStore()
    @State private var clock = ClockStore()

    var body: some Scene {
        WindowGroup("EasyBar", id: "main") {
            ContentView()
                .environment(runningAppsStore)
                .environment(clock)
                .frame(minWidth: 1040, minHeight: 680)
                .task {
                    runningAppsStore.refresh()
                    clock.start()
                }
        }
        .commands {
            CommandMenu("Dashboard") {
                Button("Refresh Running Apps") {
                    runningAppsStore.refresh()
                }
                .keyboardShortcut("r", modifiers: [.command])

                Button("Hide EasyBar") {
                    NSApp.hide(nil)
                }
                .keyboardShortcut("h", modifiers: [.command, .shift])
            }
        }

        Settings {
            SettingsView()
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
    }
}
