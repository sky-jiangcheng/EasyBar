import Foundation
import Observation

@Observable
@MainActor
final class SettingsStore {
    var aggregationMode: AggregationMode = .aggregation
    var aggregationIcon: AggregationIconType = .dots
    var autoHideDelay: TimeInterval = 5.0
    var refreshInterval: TimeInterval = 2.0
    var iconSpacing: IconSpacing = .default
    var hiddenBundleIDs: Set<String> = []
    var customOrder: [String] = []

    enum AggregationMode: String, CaseIterable {
        case aggregation = "Aggregation"
        case normal = "Normal"
        case disabled = "Disabled"
    }

    enum AggregationIconType: String, CaseIterable, Identifiable {
        case dots = "Three Dots"
        case grid = "Grid"
        case chevron = "Chevron"
        case square = "Square"
        case circle = "Circle"
        case transparent = "Transparent"

        var id: String { rawValue }

        var systemImage: String {
            switch self {
            case .dots: return "ellipsis"
            case .grid: return "square.grid.2x2"
            case .chevron: return "chevron.down"
            case .square: return "square"
            case .circle: return "circle"
            case .transparent: return "circle.dotted"
            }
        }
    }

    enum IconSpacing: String, CaseIterable, Identifiable {
        case `default` = "Default"
        case compact = "Compact"
        case small = "Small"
        case none = "None"

        var id: String { rawValue }

        var value: CGFloat {
            switch self {
            case .default: return 8
            case .compact: return 4
            case .small: return 2
            case .none: return 0
            }
        }
    }

    private let defaults = UserDefaults.standard

    init() {
        load()
    }

    func load() {
        aggregationMode = AggregationMode(rawValue: defaults.string(forKey: "aggregationMode") ?? "") ?? .aggregation
        aggregationIcon = AggregationIconType(rawValue: defaults.string(forKey: "aggregationIcon") ?? "") ?? .dots
        autoHideDelay = defaults.double(forKey: "autoHideDelay") > 0 ? defaults.double(forKey: "autoHideDelay") : 5.0
        refreshInterval = defaults.double(forKey: "refreshInterval") > 0 ? defaults.double(forKey: "refreshInterval") : 2.0
        iconSpacing = IconSpacing(rawValue: defaults.string(forKey: "iconSpacing") ?? "") ?? .default
        hiddenBundleIDs = Set(defaults.stringArray(forKey: "hiddenBundleIDs") ?? [])
        customOrder = defaults.stringArray(forKey: "customOrder") ?? []
    }

    func save() {
        defaults.set(aggregationMode.rawValue, forKey: "aggregationMode")
        defaults.set(aggregationIcon.rawValue, forKey: "aggregationIcon")
        defaults.set(autoHideDelay, forKey: "autoHideDelay")
        defaults.set(refreshInterval, forKey: "refreshInterval")
        defaults.set(iconSpacing.rawValue, forKey: "iconSpacing")
        defaults.set(Array(hiddenBundleIDs), forKey: "hiddenBundleIDs")
        defaults.set(customOrder, forKey: "customOrder")
    }

    func toggleHidden(bundleID: String) {
        if hiddenBundleIDs.contains(bundleID) {
            hiddenBundleIDs.remove(bundleID)
        } else {
            hiddenBundleIDs.insert(bundleID)
        }
        save()
    }

    func isHidden(bundleID: String) -> Bool {
        hiddenBundleIDs.contains(bundleID)
    }

    func moveItem(from source: IndexSet, to destination: Int) {
        customOrder.move(fromOffsets: source, toOffset: destination)
        save()
    }

    func addToOrder(bundleID: String) {
        if !customOrder.contains(bundleID) {
            customOrder.append(bundleID)
            save()
        }
    }
}
