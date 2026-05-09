import SwiftUI
import SwiftData

struct DashboardView: View {

    // MARK: - Properties

    @Query private var allSubscriptions: [Subscription]
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
            }
            .padding()
        }
        .navigationTitle("Dashboard")
        .background(DesignTokens.windowBackground)
        #if os(iOS)
        .safeAreaPadding(.bottom, 64)
        #endif
    }
}

#Preview {
    NavigationStack {
        DashboardView()
    }
    .modelContainer(makePreviewContainer())
}
