import SwiftUI
import SwiftData

struct UpcomingRenewalsCard: View {
    let activeSubscriptions: [Subscription]

    private var upcoming: [Subscription] {
        Array(activeSubscriptions.sorted { $0.nextDueDate < $1.nextDueDate }.prefix(5))
    }

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
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 12).fill(.background))
        .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
    }

    private func daysUntilBadge(for subscription: Subscription) -> some View {
        let days = Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: Date()), to: Calendar.current.startOfDay(for: subscription.nextDueDate)).day ?? 0
        let text = days <= 0 ? "Today" : "\(days)d"
        let isUrgent = days <= 3
        return Text(text)
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
