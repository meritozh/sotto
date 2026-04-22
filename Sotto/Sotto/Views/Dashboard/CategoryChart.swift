import SwiftUI
import SwiftData
import Charts

struct CategoryChart: View {

    // MARK: - Properties

    let activeSubscriptions: [Subscription]
    let exchangeRate: ExchangeRate?
    @AppStorage(AppConstants.currencyStorageKey) private var baseCurrency = "USD"

    // MARK: - Computed Properties

    private var categoryBreakdown: [(name: String, colorHex: String, amount: Decimal)] {
        var map: [String: (colorHex: String, amount: Decimal)] = [:]
        for sub in activeSubscriptions {
            let catName = sub.category?.name ?? "Uncategorized"
            let catColor = sub.category?.colorHex ?? "#B0B0B0"
            var monthly = BillingCycleCalculator.monthlyEquivalent(amount: sub.amount, cycle: sub.billingCycle)
            if let rate = exchangeRate {
                monthly = rate.convertToBase(amount: monthly, from: sub.currencyCode)
            }
            let existing = map[catName] ?? (colorHex: catColor, amount: 0)
            map[catName] = (colorHex: catColor, amount: existing.amount + monthly)
        }
        return map.map { (name: $0.key, colorHex: $0.value.colorHex, amount: $0.value.amount) }
            .sorted { $0.amount > $1.amount }
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("By Category", systemImage: "chart.pie")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if categoryBreakdown.isEmpty {
                Text("No active subscriptions")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 150)
            } else {
                Chart(categoryBreakdown, id: \.name) { item in
                    SectorMark(
                        angle: .value("Amount", NSDecimalNumber(decimal: item.amount).doubleValue),
                        innerRadius: .ratio(0.5),
                        angularInset: 1
                    )
                    .foregroundStyle(Color(hex: item.colorHex))
                    .annotation(position: .overlay) {
                        Text(item.name)
                            .font(.caption2)
                            .fontWeight(.medium)
                    }
                }
                .frame(height: 180)

                VStack(alignment: .leading, spacing: 4) {
                    ForEach(categoryBreakdown, id: \.name) { item in
                        HStack {
                            Circle()
                                .fill(Color(hex: item.colorHex))
                                .frame(width: 8, height: 8)
                            Text(item.name)
                                .font(.caption)
                            Spacer()
                            Text(item.amount, format: .currency(code: baseCurrency))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .cardStyle()
    }
}
