import SwiftUI
import SwiftData

struct DashboardView: View {
    @Query private var allSubscriptions: [Subscription]
    @Query(sort: \PaymentHistory.paidDate, order: .reverse)
    private var recentPayments: [PaymentHistory]
    @Query private var exchangeRates: [ExchangeRate]
    @AppStorage("baseCurrency") private var baseCurrency = "USD"

    private var activeSubscriptions: [Subscription] {
        allSubscriptions.filter { $0.status == .active }
    }

    private var currentExchangeRate: ExchangeRate? {
        exchangeRates.first { $0.baseCurrency == baseCurrency }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                HStack(alignment: .top, spacing: 16) {
                    SpendingCard(activeSubscriptions: activeSubscriptions, exchangeRate: currentExchangeRate)
                    CategoryChart(activeSubscriptions: activeSubscriptions, exchangeRate: currentExchangeRate)
                }

                HStack(alignment: .top, spacing: 16) {
                    UpcomingRenewalsCard(activeSubscriptions: activeSubscriptions)
                    recentActivityCard
                }
            }
            .padding()
        }
        .navigationTitle("Dashboard")
        #if os(macOS)
        .background(Color(nsColor: .windowBackgroundColor))
        #else
        .background(Color(.systemGroupedBackground))
        #endif
    }

    private var recentActivityCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Recent Activity", systemImage: "clock.arrow.circlepath")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            let recent = Array(recentPayments.prefix(5))
            if recent.isEmpty {
                Text("No recorded payments yet")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 80)
            } else {
                ForEach(recent) { payment in
                    HStack {
                        Text(payment.subscription?.name ?? "Unknown")
                            .lineLimit(1)
                        Spacer()
                        Text(payment.amount, format: .currency(code: payment.currencyCode))
                            .font(.subheadline)
                        Text(payment.paidDate, format: .dateTime.month(.abbreviated).day())
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    if payment.id != recent.last?.id {
                        Divider()
                    }
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 12).fill(.background))
        .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
    }
}
