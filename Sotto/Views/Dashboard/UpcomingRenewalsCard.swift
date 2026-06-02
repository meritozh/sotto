import SwiftUI
import SwiftData

struct RenewalTimelineGroup: Identifiable {
    let date: Date
    let items: [Subscription]

    var id: Date { date }
}

enum RenewalTimeline {
    static func groups(
        for subscriptions: [Subscription],
        asOf referenceDate: Date = Date(),
        limit: Int = 8,
        calendar: Calendar = .current
    ) -> [RenewalTimelineGroup] {
        let upcoming = subscriptions
            .filter { $0.status == .active }
            .sorted { lhs, rhs in
                let lhsDate = lhs.currentDueDate(asOf: referenceDate, calendar: calendar)
                let rhsDate = rhs.currentDueDate(asOf: referenceDate, calendar: calendar)
                if lhsDate == rhsDate {
                    return lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
                }
                return lhsDate < rhsDate
            }
            .prefix(limit)

        let grouped = Dictionary(grouping: upcoming) { subscription in
            calendar.startOfDay(for: subscription.currentDueDate(asOf: referenceDate, calendar: calendar))
        }

        return grouped.keys.sorted().map { date in
            RenewalTimelineGroup(date: date, items: grouped[date] ?? [])
        }
    }
}

struct RenewalTimelineCard: View {

    // MARK: - Properties

    let activeSubscriptions: [Subscription]
    private let maxItems = 8
    @Environment(\.locale) private var locale

    // MARK: - Computed Properties

    private var groups: [RenewalTimelineGroup] {
        RenewalTimeline.groups(for: activeSubscriptions, limit: maxItems)
    }

    private var itemCount: Int {
        groups.reduce(0) { $0 + $1.items.count }
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                Label("Renewal Timeline", systemImage: "clock")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Spacer()

                if itemCount > 0 {
                    Text("\(itemCount) upcoming")
                        .font(.caption)
                        .foregroundStyle(DesignTokens.label3)
                        .monospacedDigit()
                }
            }

            if groups.isEmpty {
                Text("No upcoming renewals")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 96)
            } else {
                VStack(alignment: .leading, spacing: 14) {
                    ForEach(groups) { group in
                        timelineGroup(group)
                    }
                }
            }
        }
        .cardStyle()
    }

    // MARK: - Private Views

    private func timelineGroup(_ group: RenewalTimelineGroup) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            title(for: group.date)
                .cardSectionHeader()

            VStack(spacing: 0) {
                ForEach(group.items) { subscription in
                    timelineRow(subscription)
                    if subscription.id != group.items.last?.id {
                        Divider()
                            .padding(.leading, 38)
                    }
                }
            }
        }
    }

    private func timelineRow(_ subscription: Subscription) -> some View {
        HStack(spacing: 10) {
            Image(systemName: subscription.icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(subscription.category.map { Color(hex: $0.colorHex) } ?? .secondary)
                .frame(width: 28, height: 28)
                .background(Circle().fill(DesignTokens.kpiSurface))

            VStack(alignment: .leading, spacing: 2) {
                Text(subscription.name)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(DesignTokens.label)
                    .lineLimit(1)
                Text(subscription.billingCycle.displayName)
                    .font(.caption)
                    .foregroundStyle(DesignTokens.label3)
            }

            Spacer(minLength: 12)

            VStack(alignment: .trailing, spacing: 3) {
                Text(subscription.amount, format: .currency(code: subscription.currencyCode))
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(DesignTokens.label)
                    .monospacedDigit()
                daysUntilBadge(for: subscription)
            }
        }
        .padding(.vertical, 7)
    }

    private func daysUntilBadge(for subscription: Subscription) -> some View {
        let days = subscription.daysUntilDue
        let isUrgent = days <= AppConstants.urgentDaysThreshold
        let label: Text
        if days <= 0 {
            label = Text("Today")
        } else if days == 1 {
            label = Text("Tomorrow")
        } else {
            label = Text("in \(days)d")
        }

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

    private func title(for date: Date) -> Text {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return Text("Today")
        }
        if calendar.isDateInTomorrow(date) {
            return Text("Tomorrow")
        }
        return Text(verbatim: date.formatted(.dateTime.month(.abbreviated).day().locale(locale)))
    }
}

#Preview {
    RenewalTimelineCard(activeSubscriptions: makeSampleSubscriptions())
        .frame(width: 360)
        .padding()
}
