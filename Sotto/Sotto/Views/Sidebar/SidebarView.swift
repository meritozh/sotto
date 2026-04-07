import SwiftUI
import SwiftData

enum SidebarDestination: String, CaseIterable, Identifiable {
    case dashboard
    case subscriptions
    case calendar
    case categories
    case settings

    var id: String { rawValue }

    var label: String {
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

struct SidebarView: View {
    @Binding var selection: SidebarDestination?
    @Query private var allSubscriptions: [Subscription]

    private var activeSubscriptions: [Subscription] {
        allSubscriptions.filter { $0.status == .active }
    }

    private var urgentCount: Int {
        let threeDaysFromNow = Calendar.current.date(byAdding: .day, value: 3, to: Date())!
        return activeSubscriptions.filter { $0.nextDueDate <= threeDaysFromNow }.count
    }

    private var monthlyTotal: Decimal {
        activeSubscriptions.reduce(Decimal.zero) { total, sub in
            total + BillingCycleCalculator.monthlyEquivalent(amount: sub.amount, cycle: sub.billingCycle)
        }
    }

    var body: some View {
        List(selection: $selection) {
            Section("Navigation") {
                ForEach(SidebarDestination.allCases) { dest in
                    Label(dest.label, systemImage: dest.icon)
                        .tag(dest)
                        .badge(dest == .subscriptions ? urgentCount : 0)
                }
            }

            Section("Quick Stats") {
                LabeledContent("Monthly Total") {
                    Text(monthlyTotal, format: .currency(code: "USD"))
                        .font(.headline)
                }
                LabeledContent("Due Soon") {
                    Text("\(urgentCount)")
                        .font(.headline)
                        .foregroundStyle(urgentCount > 0 ? .red : .secondary)
                }
            }
        }
        .listStyle(.sidebar)
    }
}
