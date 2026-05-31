import SwiftUI
import SwiftData

struct CategoryChart: View {

    // MARK: - Properties

    let activeSubscriptions: [Subscription]
    let exchangeRate: ExchangeRate?
    @AppStorage(AppConstants.currencyStorageKey) private var baseCurrency = "USD"
    @Environment(\.locale) private var locale

    // MARK: - Types

    struct Slice: Identifiable {
        let id: String
        let name: String
        let color: Color
        let amount: Decimal
    }

    // MARK: - Computed Properties

    private var slices: [Slice] {
        var map: [String: (name: String, colorHex: String, amount: Decimal)] = [:]
        for sub in activeSubscriptions {
            let catID = sub.category?.name ?? "Uncategorized"
            let catName = sub.category?.localizedName(for: locale) ?? uncategorizedName
            let catColor = sub.category?.colorHex ?? "#8a8f99"
            var monthly = BillingCycleCalculator.monthlyEquivalent(amount: sub.amount, cycle: sub.billingCycle)
            if let rate = exchangeRate {
                monthly = rate.convertToBase(amount: monthly, from: sub.currencyCode)
            }
            let existing = map[catID] ?? (name: catName, colorHex: catColor, amount: 0)
            map[catID] = (name: existing.name, colorHex: catColor, amount: existing.amount + monthly)
        }
        return map
            .map { Slice(id: $0.key, name: $0.value.name, color: Color(hex: $0.value.colorHex), amount: $0.value.amount) }
            .sorted { $0.amount > $1.amount }
    }

    private var total: Decimal {
        slices.reduce(Decimal.zero) { $0 + $1.amount }
    }

    private var uncategorizedName: String {
        locale.identifier.lowercased().hasPrefix("zh") ? "未分类" : "Uncategorized"
    }

    private var maxAmount: Decimal {
        slices.first?.amount ?? 1
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "waveform.path.ecg")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(DesignTokens.label3)
                Text("By category").cardSectionHeader()
            }

            if slices.isEmpty {
                Text("No active subscriptions")
                    .font(.system(size: 13))
                    .foregroundStyle(DesignTokens.label3)
                    .frame(maxWidth: .infinity, minHeight: 150)
            } else {
                HStack(alignment: .center, spacing: 18) {
                    Donut(slices: slices, total: total, currency: baseCurrency)
                        .frame(width: 132, height: 132)

                    VStack(spacing: 0) {
                        ForEach(Array(slices.enumerated()), id: \.element.id) { index, slice in
                            categoryRow(slice)
                            if index < slices.count - 1 {
                                Rectangle()
                                    .fill(DesignTokens.contentDivider)
                                    .frame(height: 0.5)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .cardStyle()
    }

    // MARK: - Subviews

    private func categoryRow(_ slice: Slice) -> some View {
        let progress = total > 0 ? NSDecimalNumber(decimal: slice.amount / maxAmount).doubleValue : 0
        return HStack(spacing: 10) {
            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .fill(slice.color)
                .frame(width: 10, height: 10)

            Text(slice.name)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(DesignTokens.label)
                .lineLimit(2)
                .frame(width: 90, alignment: .leading)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(DesignTokens.contentDivider)
                    Capsule()
                        .fill(slice.color)
                        .frame(width: geo.size.width * progress)
                }
            }
            .frame(height: 6)
            .frame(maxWidth: .infinity)

            Text(slice.amount, format: .currency(code: baseCurrency))
                .font(.system(size: 12))
                .monospacedDigit()
                .foregroundStyle(DesignTokens.label2)
                .frame(width: 70, alignment: .trailing)
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Donut

private struct Donut: View {
    let slices: [CategoryChart.Slice]
    let total: Decimal
    let currency: String

    private let thickness: CGFloat = 16

    var body: some View {
        ZStack {
            GeometryReader { geo in
                let size = min(geo.size.width, geo.size.height)
                let radius = (size - thickness) / 2
                let center = CGPoint(x: size / 2, y: size / 2)
                let totalDouble = NSDecimalNumber(decimal: total).doubleValue

                ZStack {
                    Circle()
                        .stroke(DesignTokens.contentDivider, lineWidth: thickness)
                        .frame(width: size - thickness, height: size - thickness)
                        .position(center)

                    if totalDouble > 0 {
                        ForEach(Array(slicesWithAngles().enumerated()), id: \.offset) { _, item in
                            DonutSlice(start: item.start, end: item.end)
                                .stroke(item.color, lineWidth: thickness)
                                .frame(width: radius * 2, height: radius * 2)
                                .position(center)
                        }
                    }
                }
            }

            VStack(spacing: 2) {
                Text("Monthly")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(DesignTokens.label3)
                Text(total, format: .currency(code: currency))
                    .font(.system(size: 18, weight: .semibold))
                    .monospacedDigit()
                    .foregroundStyle(DesignTokens.label)
            }
        }
    }

    private func slicesWithAngles() -> [(start: Angle, end: Angle, color: Color)] {
        let totalDouble = NSDecimalNumber(decimal: total).doubleValue
        guard totalDouble > 0 else { return [] }
        var acc: Double = 0
        return slices.map { slice in
            let frac = NSDecimalNumber(decimal: slice.amount).doubleValue / totalDouble
            let start = Angle.degrees(acc * 360 - 90)
            acc += frac
            let end = Angle.degrees(acc * 360 - 90)
            return (start, end, slice.color)
        }
    }
}

private struct DonutSlice: Shape {
    let start: Angle
    let end: Angle

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        path.addArc(center: center, radius: radius, startAngle: start, endAngle: end, clockwise: false)
        return path
    }
}

#Preview {
    CategoryChart(activeSubscriptions: makeSampleSubscriptions(), exchangeRate: nil)
        .frame(width: 560)
        .padding()
        .background(DesignTokens.windowBackground)
}
