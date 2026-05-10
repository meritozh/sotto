import SwiftUI

struct SubscriptionRow: View {
    let subscription: Subscription
    var isSelected: Bool = false
    var isCompact: Bool = false

    // MARK: - Body

    var body: some View {
        HStack(spacing: 12) {
            iconBadge
                .frame(width: 36, alignment: .leading)

            VStack(alignment: .leading, spacing: 2) {
                Text(subscription.name)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(DesignTokens.label)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    if let category = subscription.category {
                        Circle()
                            .fill(Color(hex: category.colorHex))
                            .frame(width: 7, height: 7)
                        Text(category.name)
                    } else {
                        Text("Uncategorized")
                    }
                    if isCompact {
                        Text("·").foregroundStyle(DesignTokens.label4)
                        Text(subscription.billingCycle.displayName)
                    }
                }
                .font(.system(size: 11))
                .foregroundStyle(DesignTokens.label3)
                .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if !isCompact {
                Text(subscription.billingCycle.displayName)
                    .font(.system(size: 12))
                    .foregroundStyle(DesignTokens.label2)
                    .frame(width: 130, alignment: .leading)

                Text(subscription.currentDueDate, format: .dateTime.month(.abbreviated).day())
                    .font(.system(size: 12))
                    .foregroundStyle(DesignTokens.label2)
                    .monospacedDigit()
                    .frame(width: 130, alignment: .leading)
            }

            VStack(alignment: .trailing, spacing: 2) {
                Text(subscription.amount, format: .currency(code: subscription.currencyCode))
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(DesignTokens.label)
                    .monospacedDigit()
                dueLabel
                    .font(.system(size: 11, weight: isSoon ? .medium : .regular))
                    .foregroundStyle(isSoon ? DesignTokens.dueSoon : DesignTokens.label3)
                    .monospacedDigit()
            }
            .frame(width: isCompact ? nil : 110, alignment: .trailing)
            .fixedSize(horizontal: isCompact, vertical: false)
        }
        .padding(.horizontal, isCompact ? 16 : 18)
        .padding(.vertical, 10)
        .frame(height: 56)
        .background(isSelected ? DesignTokens.accentTint : Color.clear)
    }

    // MARK: - Subviews

    private var iconBadge: some View {
        let bg = subscription.category.map { Color(hex: $0.colorHex) } ?? Color(hex: "#8a8f99")
        return RoundedRectangle(cornerRadius: 8, style: .continuous)
            .fill(bg)
            .frame(width: 32, height: 32)
            .overlay(
                Image(systemName: subscription.icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .strokeBorder(Color.black.opacity(0.06), lineWidth: 0.5)
            )
    }

    // MARK: - Helpers

    private var isSoon: Bool {
        subscription.status == .active && subscription.daysUntilDue <= AppConstants.soonDaysThreshold
    }

    private var dueLabel: Text {
        guard subscription.status == .active else { return Text(subscription.status.displayName) }
        let days = subscription.daysUntilDue
        if days <= 0 { return Text("today") }
        if days == 1 { return Text("tomorrow") }
        return Text("in \(days) days")
    }
}

#Preview {
    VStack(spacing: 0) {
        SubscriptionRow(subscription: makeSampleSubscription())
        Divider()
        SubscriptionRow(subscription: makeSampleSubscription(name: "Netflix", icon: "play.tv", amount: 16, daysUntilDue: 7), isSelected: true)
        Divider()
        SubscriptionRow(subscription: makeSampleSubscription(name: "Spotify", icon: "music.note", amount: 10, billingCycle: .yearly, daysUntilDue: 120))
    }
    .frame(width: 720)
    .background(DesignTokens.windowBackground)
}
