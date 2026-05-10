import SwiftUI
import SwiftData

struct UpcomingRenewalsCard: View {

    // MARK: - Properties

    let activeSubscriptions: [Subscription]

    // MARK: - Computed Properties

    private var upcoming: [Subscription] {
        Array(activeSubscriptions.sorted { $0.currentDueDate < $1.currentDueDate }.prefix(5))
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Upcoming Renewals", systemImage: "clock")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if upcoming.isEmpty {
                Text("No upcoming renewals")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 80)
            } else {
                ForEach(upcoming) { sub in
                    HStack {
                        Image(systemName: sub.icon)
                            .frame(width: 24)
                        Text(sub.name)
                            .lineLimit(1)
                        Spacer()
                        Text(sub.amount, format: .currency(code: sub.currencyCode))
                            .font(.subheadline)
                        daysUntilBadge(for: sub)
                    }
                    if sub.id != upcoming.last?.id {
                        Divider()
                    }
                }
            }
        }
        .cardStyle()
    }

    // MARK: - Private Views

    private func daysUntilBadge(for subscription: Subscription) -> some View {
        let days = subscription.daysUntilDue
        let isUrgent = days <= AppConstants.urgentDaysThreshold
        let label: Text = days <= 0 ? Text("Today") : Text("\(days)d")
        return label
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(
                Capsule().fill(isUrgent ? Color.red.opacity(0.15) : Color.secondary.opacity(0.1))
            )
            .foregroundStyle(isUrgent ? .red : .secondary)
    }
}

#Preview {
    UpcomingRenewalsCard(activeSubscriptions: makeSampleSubscriptions())
        .frame(width: 300)
        .padding()
}
