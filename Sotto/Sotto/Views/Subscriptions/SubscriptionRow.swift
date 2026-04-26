import SwiftUI

struct SubscriptionRow: View {
    let subscription: Subscription

    // MARK: - Body

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: subscription.icon)
                .font(.title2)
                .frame(width: 36, height: 36)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(subscription.category.map { Color(hex: $0.colorHex).opacity(0.2) } ?? Color.gray.opacity(0.1))
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(subscription.name)
                    .font(.body)
                    .fontWeight(.medium)
                HStack(spacing: 4) {
                    Text(subscription.billingCycle.displayName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if let category = subscription.category {
                        Text("\u{00B7}")
                            .foregroundStyle(.secondary)
                        Text(category.name)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(subscription.amount, format: .currency(code: subscription.currencyCode))
                    .font(.body)
                    .fontWeight(.medium)
                if subscription.status == .active {
                    Text(subscription.daysUntilDue <= 0 ? "Due today" : "in \(subscription.daysUntilDue) days")
                        .font(.caption)
                        .foregroundStyle(subscription.daysUntilDue <= AppConstants.urgentDaysThreshold ? .red : .secondary)
                } else {
                    Text(subscription.status.displayName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    VStack(spacing: 0) {
        SubscriptionRow(subscription: makeSampleSubscription())
            .padding(.horizontal)
        Divider().padding(.leading)
        SubscriptionRow(subscription: makeSampleSubscription(name: "Netflix", icon: "play.tv", amount: 16, daysUntilDue: 7))
            .padding(.horizontal)
    }
    .frame(width: 400)
}
