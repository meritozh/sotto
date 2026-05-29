import Foundation

enum SidebarDestination: String, CaseIterable, Identifiable {
    case dashboard
    case subscriptions
    case addSubscription
    case categories
    case settings

    // MARK: - Computed Properties
    var id: String { rawValue }

    var label: LocalizedStringResource {
        switch self {
        case .dashboard: "Dashboard"
        case .subscriptions: "All Subscriptions"
        case .addSubscription: "Add Subscription"
        case .categories: "Categories"
        case .settings: "Settings"
        }
    }

    var icon: String {
        switch self {
        case .dashboard: "square.grid.2x2"
        case .subscriptions: "list.bullet"
        case .addSubscription: "plus"
        case .categories: "tag"
        case .settings: "gearshape"
        }
    }
}
