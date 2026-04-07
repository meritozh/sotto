import SwiftUI
import SwiftData

struct SpendingCard: View {
    let activeSubscriptions: [Subscription]

    private var monthlyTotal: Decimal {
        activeSubscriptions.reduce(Decimal.zero) { total, sub in
            total + BillingCycleCalculator.monthlyEquivalent(amount: sub.amount, cycle: sub.billingCycle)
        }
    }

    private var yearlyTotal: Decimal {
        monthlyTotal * 12
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Monthly Spending", systemImage: "creditcard")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text(monthlyTotal, format: .currency(code: "USD"))
                .font(.system(size: 36, weight: .bold, design: .rounded))

            HStack {
                Text("Yearly estimate:")
                    .foregroundStyle(.secondary)
                Text(yearlyTotal, format: .currency(code: "USD"))
                    .fontWeight(.medium)
            }
            .font(.subheadline)

            Text("\(activeSubscriptions.count) active subscriptions")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 12).fill(.background))
        .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
    }
}
