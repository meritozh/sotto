import SwiftUI
import SwiftData

struct SpendingCard: View {

    // MARK: - Properties

    let activeSubscriptions: [Subscription]
    let exchangeRate: ExchangeRate?
    @AppStorage(AppConstants.currencyStorageKey) private var baseCurrency = "USD"

    // MARK: - Computed Properties

    private var monthlyTotal: Decimal {
        activeSubscriptions.reduce(Decimal.zero) { total, sub in
            let monthly = BillingCycleCalculator.monthlyEquivalent(amount: sub.amount, cycle: sub.billingCycle)
            if let rate = exchangeRate {
                return total + rate.convertToBase(amount: monthly, from: sub.currencyCode)
            }
            return total + monthly
        }
    }

    private var yearlyTotal: Decimal {
        monthlyTotal * 12
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Monthly Spending", systemImage: "creditcard")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text(monthlyTotal, format: .currency(code: baseCurrency))
                .font(.system(size: 36, weight: .bold, design: .rounded))

            HStack {
                Text("Yearly estimate:")
                    .foregroundStyle(.secondary)
                Text(yearlyTotal, format: .currency(code: baseCurrency))
                    .fontWeight(.medium)
            }
            .font(.subheadline)

            Text("\(activeSubscriptions.count) active subscriptions")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .cardStyle()
    }
}

#Preview {
    SpendingCard(activeSubscriptions: makeSampleSubscriptions(), exchangeRate: nil)
        .frame(width: 300)
        .padding()
}
