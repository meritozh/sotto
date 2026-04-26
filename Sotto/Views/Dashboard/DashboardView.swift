import SwiftUI
import SwiftData

struct DashboardView: View {

    // MARK: - Properties

    @Query private var allSubscriptions: [Subscription]
    @Query(sort: \PaymentHistory.paidDate, order: .reverse)
    private var recentPayments: [PaymentHistory]
    @Query private var exchangeRates: [ExchangeRate]
    @AppStorage(AppConstants.currencyStorageKey) private var baseCurrency = "USD"

    // MARK: - Computed Properties

    private var activeSubscriptions: [Subscription] {
        allSubscriptions.activeOnly
    }

    private var currentExchangeRate: ExchangeRate? {
        exchangeRates.first { $0.baseCurrency == baseCurrency }
    }

    #if os(iOS)
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    #endif

    private var isCompact: Bool {
        #if os(iOS)
        return horizontalSizeClass == .compact
        #else
        return false
        #endif
    }

    // MARK: - Body

    var body: some View {
        ScrollView {
            MasonryLayout(columns: isCompact ? 1 : 2, spacing: 16) {
                SpendingCard(activeSubscriptions: activeSubscriptions, exchangeRate: currentExchangeRate)
                CategoryChart(activeSubscriptions: activeSubscriptions, exchangeRate: currentExchangeRate)
                UpcomingRenewalsCard(activeSubscriptions: activeSubscriptions)
                recentActivityCard
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

    // MARK: - Private Views

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
        .cardStyle()
    }
}

#Preview {
    NavigationStack {
        DashboardView()
    }
    .modelContainer(makePreviewContainer())
}
