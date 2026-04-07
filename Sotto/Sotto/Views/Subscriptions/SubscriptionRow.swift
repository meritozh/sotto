import SwiftUI

struct SubscriptionRow: View {
    let subscription: Subscription

    private var daysUntilDue: Int {
        Calendar.current.dateComponents([.day], from: Date(), to: subscription.nextDueDate).day ?? 0
    }

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
                    Text(daysUntilDue <= 0 ? "Due today" : "in \(daysUntilDue) days")
                        .font(.caption)
                        .foregroundStyle(daysUntilDue <= 3 ? .red : .secondary)
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
