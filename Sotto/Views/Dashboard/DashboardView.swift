import SwiftUI
import SwiftData
import TipKit

struct DashboardView: View {

    // MARK: - Properties

    var onAddSubscription: () -> Void = {}

    @Query private var allSubscriptions: [Subscription]
    @Query private var exchangeRates: [ExchangeRate]
    @AppStorage(AppConstants.currencyStorageKey) private var baseCurrency = "USD"

    private let addFirstSubscriptionTip = AddFirstSubscriptionTip()

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
            TipView(addFirstSubscriptionTip) { action in
                if action.id == AddFirstSubscriptionTip.addActionID {
                    onAddSubscription()
                }
            }
            .padding(.horizontal)
            .padding(.top, 8)

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
        .task {
            AddFirstSubscriptionTip.subscriptionCount = allSubscriptions.count
        }
        .onChange(of: allSubscriptions.count) { _, newValue in
            AddFirstSubscriptionTip.subscriptionCount = newValue
        }
    }
}

#Preview {
    NavigationStack {
        DashboardView()
    }
    .modelContainer(makePreviewContainer())
}
