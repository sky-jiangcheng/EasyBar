import XCTest

@testable import StatusBar_Pro

@MainActor
final class LogicTests: XCTestCase {
    // MARK: - MenuBarMonitor.baseBundleID

    func testBaseBundleIDKeepsFirstTwoSegments() {
        XCTAssertEqual(MenuBarMonitor.baseBundleID(of: "com.docker.helper"), "com.docker")
        XCTAssertEqual(MenuBarMonitor.baseBundleID(of: "com.docker"), "com.docker")
        XCTAssertEqual(MenuBarMonitor.baseBundleID(of: "com.apple.finder"), "com.apple")
    }

    func testBaseBundleIDSegmentAlignmentPreventsPrefixAbsorption() {
        // The comparison must be segment-aligned, not a prefix match: otherwise
        // com.docker would also dominate com.dockerized.app.
        XCTAssertNotEqual(
            MenuBarMonitor.baseBundleID(of: "com.docker.helper"),
            MenuBarMonitor.baseBundleID(of: "com.dockerized.app")
        )
    }

    func testBaseBundleIDSingleSegmentIsNil() {
        XCTAssertNil(MenuBarMonitor.baseBundleID(of: "localhost"))
        XCTAssertNil(MenuBarMonitor.baseBundleID(of: ""))
    }

    // MARK: - AggregationPanel.heightFor

    func testHeightForEmptyListUsesFixedMinimum() {
        XCTAssertEqual(AggregationPanel.heightFor(statusbarCount: 0, spacing: 8), 80)
    }

    func testHeightForGrowsPerRowThenCaps() {
        let layout = AggregationPanel.Layout.self
        XCTAssertEqual(
            AggregationPanel.heightFor(statusbarCount: 1, spacing: 8),
            layout.verticalPadding + layout.rowHeight
        )
        // 10 apps / 5 columns = 2 rows: exactly one inter-row spacing gap.
        XCTAssertEqual(
            AggregationPanel.heightFor(statusbarCount: 10, spacing: 4),
            layout.verticalPadding + 2 * layout.rowHeight + 4
        )
        // 15 apps = 3 rows, but the panel caps at maxVisibleRows.
        XCTAssertEqual(
            AggregationPanel.heightFor(statusbarCount: 15, spacing: 4),
            layout.verticalPadding + CGFloat(layout.maxVisibleRows) * layout.rowHeight + 4
        )
    }

    // MARK: - MenuBarMonitor.sortedByCustomOrder

    private func item(_ id: String, _ name: String) -> MenuBarMonitor.MenuBarItem {
        MenuBarMonitor.MenuBarItem(
            id: id,
            bundleIdentifier: id,
            processName: name,
            icon: nil,
            appType: .dockOnly
        )
    }

    func testSortedByCustomOrderPutsOrderedFirstThenUnorderedAlphabetically() {
        let store = SettingsStore()
        store.customOrder = ["b"]
        let monitor = MenuBarMonitor(settingsStore: store)

        let sorted = monitor.sortedByCustomOrder([
            item("c", "Cherry"),
            item("b", "Banana"),
            item("a", "Apple"),
        ])

        XCTAssertEqual(sorted.map(\.id), ["b", "a", "c"])
    }

    func testSortedByCustomOrderWithoutOrderKeepsInputOrder() {
        // With no custom order the input is passed through; the alphabetical
        // baseline comes from getMenuItemsFromRunningApps.
        let store = SettingsStore()
        store.customOrder = []
        let monitor = MenuBarMonitor(settingsStore: store)

        let sorted = monitor.sortedByCustomOrder([
            item("c", "Cherry"),
            item("a", "Apple"),
        ])

        XCTAssertEqual(sorted.map(\.id), ["c", "a"])
    }

    func testSortedByCustomOrderIgnoresUnknownOrderedIDs() {
        // IDs of apps that have quit must not break the ordering.
        let store = SettingsStore()
        store.customOrder = ["ghost", "a"]
        let monitor = MenuBarMonitor(settingsStore: store)

        let sorted = monitor.sortedByCustomOrder([
            item("b", "Banana"),
            item("a", "Apple"),
        ])

        XCTAssertEqual(sorted.map(\.id), ["a", "b"])
    }
}
