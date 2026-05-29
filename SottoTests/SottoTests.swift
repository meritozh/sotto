import Foundation
import Testing
@testable import SottoKit

@Suite("Sotto Tests")
struct SottoTests {
    @Test func renewalTimelineGroupsActiveSubscriptionsByUpcomingDueDate() {
        let calendar = Calendar(identifier: .gregorian)
        let today = calendar.date(from: DateComponents(year: 2026, month: 5, day: 29))!
        let tomorrow = calendar.date(from: DateComponents(year: 2026, month: 5, day: 30))!
        let later = calendar.date(from: DateComponents(year: 2026, month: 6, day: 8))!

        let dueToday = makeSubscription(name: "Due Today", startDate: today, status: .active)
        let dueTomorrowB = makeSubscription(name: "Beta", startDate: tomorrow, status: .active)
        let dueTomorrowA = makeSubscription(name: "Alpha", startDate: tomorrow, status: .active)
        let dueLater = makeSubscription(name: "Later", startDate: later, status: .active)
        let paused = makeSubscription(name: "Paused", startDate: today, status: .paused)

        let groups = RenewalTimeline.groups(
            for: [dueLater, dueTomorrowB, paused, dueToday, dueTomorrowA],
            asOf: today,
            limit: 4,
            calendar: calendar
        )

        #expect(groups.map(\.date) == [today, tomorrow, later])
        #expect(groups[0].items.map(\.name) == ["Due Today"])
        #expect(groups[1].items.map(\.name) == ["Alpha", "Beta"])
        #expect(groups[2].items.map(\.name) == ["Later"])
    }

    private func makeSubscription(
        name: String,
        startDate: Date,
        status: SubscriptionStatus
    ) -> Subscription {
        Subscription(
            name: name,
            icon: "sparkle",
            amount: 10,
            currencyCode: "USD",
            billingCycle: .monthly,
            startDate: startDate,
            nextDueDate: startDate,
            status: status
        )
    }
}
