import Foundation

enum BillingCycleCalculator {

    // MARK: - Public
    static func nextDueDate(from date: Date, cycle: BillingCycle) -> Date {
        let calendar = Calendar.current
        switch cycle {
        case .weekly:
            return calendar.date(byAdding: .day, value: 7, to: date) ?? date
        case .monthly:
            return calendar.date(byAdding: .month, value: 1, to: date) ?? date
        case .quarterly:
            return calendar.date(byAdding: .month, value: 3, to: date) ?? date
        case .halfYearly:
            return calendar.date(byAdding: .month, value: 6, to: date) ?? date
        case .yearly:
            return calendar.date(byAdding: .year, value: 1, to: date) ?? date
        }
    }

    static func monthlyEquivalent(amount: Decimal, cycle: BillingCycle) -> Decimal {
        switch cycle {
        case .weekly:
            return amount * 52 / 12
        case .monthly:
            return amount
        case .quarterly:
            return amount / 3
        case .halfYearly:
            return amount / 6
        case .yearly:
            return amount / 12
        }
    }

    /// Number of billing periods that have elapsed (and presumably been billed) from
    /// `start` up to and including `asOf`. Returns 0 when `asOf < start` (subscription
    /// hasn't begun yet). Counts the first payment on `start` itself.
    static func cyclesPaid(from start: Date, asOf endDate: Date, cycle: BillingCycle) -> Int {
        guard endDate >= start else { return 0 }
        let calendar = Calendar.current
        let elapsed: Int
        switch cycle {
        case .weekly:
            elapsed = (calendar.dateComponents([.day], from: start, to: endDate).day ?? 0) / 7
        case .monthly:
            elapsed = calendar.dateComponents([.month], from: start, to: endDate).month ?? 0
        case .quarterly:
            elapsed = (calendar.dateComponents([.month], from: start, to: endDate).month ?? 0) / 3
        case .halfYearly:
            elapsed = (calendar.dateComponents([.month], from: start, to: endDate).month ?? 0) / 6
        case .yearly:
            elapsed = calendar.dateComponents([.year], from: start, to: endDate).year ?? 0
        }
        return elapsed + 1
    }
}
