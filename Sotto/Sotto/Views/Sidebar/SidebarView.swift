import SwiftUI
import SwiftData

struct SidebarView: View {

    // MARK: - Properties

    @Binding var selection: SidebarDestination
    @AppStorage(AppConstants.currencyStorageKey) private var baseCurrency = "USD"
    @Query private var allSubscriptions: [Subscription]
    @Query private var exchangeRates: [ExchangeRate]

    // MARK: - Computed Properties

    private var activeSubscriptions: [Subscription] {
        allSubscriptions.activeOnly
    }

    private var urgentCount: Int {
        let cutoff = Calendar.current.date(byAdding: .day, value: AppConstants.urgentDaysThreshold, to: Date()) ?? Date()
        return activeSubscriptions.filter { $0.nextDueDate <= cutoff }.count
    }

    private var currentExchangeRate: ExchangeRate? {
        exchangeRates.first { $0.baseCurrency == baseCurrency }
    }

    private var monthlyTotal: Decimal {
        activeSubscriptions.reduce(Decimal.zero) { total, sub in
            var monthly = BillingCycleCalculator.monthlyEquivalent(amount: sub.amount, cycle: sub.billingCycle)
            if let rate = currentExchangeRate {
                monthly = rate.convertToBase(amount: monthly, from: sub.currencyCode)
            }
            return total + monthly
        }
    }

    // MARK: - Body

    var body: some View {
        List(selection: $selection) {
            ForEach(SidebarDestination.allCases, id: \.self) { dest in
                Label(dest.label, systemImage: dest.icon)
                    .badge(dest == .subscriptions ? urgentCount : 0)
            }

            Section("Quick Stats") {
                LabeledContent("Monthly Total") {
                    Text(monthlyTotal, format: .currency(code: baseCurrency))
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

#Preview {
    @Previewable @State var selection = SidebarDestination.dashboard
    SidebarView(selection: $selection)
        .modelContainer(makePreviewContainer())
}
