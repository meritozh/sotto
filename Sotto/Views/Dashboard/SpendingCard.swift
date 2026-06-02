import SwiftUI
import SwiftData

struct SpendingCard: View {

    // MARK: - Properties

    let activeSubscriptions: [Subscription]
    let exchangeRate: ExchangeRate?
    var isCompact = false
    @AppStorage(AppConstants.currencyStorageKey) private var baseCurrency = "CNY"

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

    private var dueIn30: Int {
        let cutoff = Calendar.current.date(byAdding: .day, value: 30, to: Date()) ?? Date()
        return activeSubscriptions.filter { $0.currentDueDate <= cutoff }.count
    }

    private var avgPerSub: Decimal {
        let count = activeSubscriptions.count
        guard count > 0 else { return 0 }
        return monthlyTotal / Decimal(count)
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Circle().fill(DesignTokens.label4).frame(width: 6, height: 6)
                Text("MONTHLY SPENDING").cardSectionHeader()
            }

            Text(monthlyTotal, format: .currency(code: baseCurrency))
                .font(.system(size: isCompact ? 34 : 38, weight: .semibold))
                .monospacedDigit()
                .kerning(-0.6)
                .foregroundStyle(DesignTokens.label)
                .lineLimit(1)
                .minimumScaleFactor(0.75)

            HStack(spacing: 4) {
                Text("Yearly estimate")
                    .foregroundStyle(DesignTokens.label2)
                Text(yearlyTotal, format: .currency(code: baseCurrency))
                    .fontWeight(.semibold)
                    .monospacedDigit()
                    .foregroundStyle(DesignTokens.label)
                Text("·  \(activeSubscriptions.count) active")
                    .foregroundStyle(DesignTokens.label2)
            }
            .font(.system(size: 12))
            .lineLimit(1)
            .minimumScaleFactor(0.82)

            kpiSummary
            .padding(.top, 2)
        }
        .cardStyle(paddingH: isCompact ? 14 : 18, paddingV: 16)
    }

    // MARK: - Subviews

    @ViewBuilder
    private var kpiSummary: some View {
        if isCompact {
            Grid(horizontalSpacing: 8, verticalSpacing: 8) {
                GridRow {
                    avgPerSubKPI
                    dueIn30KPI
                }
                GridRow {
                    activeKPI
                        .gridCellColumns(2)
                }
            }
        } else {
            HStack(spacing: 10) {
                avgPerSubKPI
                dueIn30KPI
                activeKPI
            }
        }
    }

    private var avgPerSubKPI: some View {
        kpi(label: "Avg per sub",
            value: avgPerSub.formatted(.currency(code: baseCurrency)),
            suffix: "/mo")
    }

    private var dueIn30KPI: some View {
        kpi(label: "Due in 30d",
            value: "\(dueIn30)",
            suffix: nil)
    }

    private var activeKPI: some View {
        kpi(label: "Active",
            value: "\(activeSubscriptions.count)",
            suffix: nil)
    }

    private func kpi(label: LocalizedStringResource, value: String, suffix: LocalizedStringResource?) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(DesignTokens.label3)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.system(size: 18, weight: .semibold))
                    .monospacedDigit()
                    .kerning(-0.2)
                    .foregroundStyle(DesignTokens.label)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                if let suffix {
                    Text(suffix)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(DesignTokens.label2)
                        .lineLimit(1)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.radiusMD)
                .fill(DesignTokens.kpiSurface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.radiusMD)
                .strokeBorder(DesignTokens.contentDivider, lineWidth: 0.5)
        )
    }
}

#Preview {
    SpendingCard(activeSubscriptions: makeSampleSubscriptions(), exchangeRate: nil)
        .frame(width: 380)
        .padding()
        .background(DesignTokens.windowBackground)
}
