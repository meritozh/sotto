import Foundation

enum SidebarDestination: String, CaseIterable, Identifiable {
    case dashboard
    case subscriptions
    case calendar
    case categories
    case settings

    // MARK: - Computed Properties
    var id: String { rawValue }

    var label: LocalizedStringResource {
        switch self {
        case .dashboard: "Dashboard"
        case .subscriptions: "All Subscriptions"
        case .calendar: "Calendar"
        case .categories: "Categories"
        case .settings: "Settings"
        }
    }

    var icon: String {
        switch self {
        case .dashboard: "square.grid.2x2"
        case .subscriptions: "list.bullet"
        case .calendar: "calendar"
        case .categories: "tag"
        case .settings: "gearshape"
        }
    }
}
