import Foundation

extension Subscription {

    /// The next-upcoming billing date, derived live from `startDate + cycle + today`.
    /// Replaces the formerly-mutated `nextDueDate` field. The stored `nextDueDate`
    /// is preserved for SwiftData/CloudKit schema compatibility and as a sortable
    /// fallback, but UI code should display this computed value.
    var currentDueDate: Date {
        currentDueDate(asOf: Date())
    }

    func currentDueDate(asOf referenceDate: Date, calendar: Calendar = .current) -> Date {
        let today = calendar.startOfDay(for: referenceDate)
        var date = calendar.startOfDay(for: startDate)
        // Future-dated subscription (start hasn't arrived): the start IS the next due.
        if date >= today { return date }
        while date < today {
            date = calendar.startOfDay(for: BillingCycleCalculator.nextDueDate(from: date, cycle: billingCycle))
        }
        return date
    }

    var daysUntilDue: Int {
        daysUntilDue(asOf: Date())
    }

    func daysUntilDue(asOf referenceDate: Date, calendar: Calendar = .current) -> Int {
        calendar.dateComponents(
            [.day],
            from: calendar.startOfDay(for: referenceDate),
            to: calendar.startOfDay(for: currentDueDate(asOf: referenceDate, calendar: calendar))
        ).day ?? 0
    }

    /// Cumulative spend on this subscription since `startDate`, computed from the
    /// number of billing cycles that have elapsed. Assumes the first payment occurs
    /// on `startDate` itself. For paused/cancelled subscriptions we still count up
    /// to today (no per-status freeze tracked yet).
    var totalCost: Decimal {
        let cycles = BillingCycleCalculator.cyclesPaid(
            from: startDate,
            asOf: Date(),
            cycle: billingCycle
        )
        return amount * Decimal(cycles)
    }
}

extension [Subscription] {
    var activeOnly: [Subscription] {
        filter { $0.status == .active }
    }
}
