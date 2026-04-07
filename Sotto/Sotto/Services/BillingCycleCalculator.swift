import Foundation

enum BillingCycleCalculator {
    static func nextDueDate(from date: Date, cycle: BillingCycle) -> Date {
        let calendar = Calendar.current
        switch cycle {
        case .weekly:
            return calendar.date(byAdding: .day, value: 7, to: date)!
        case .monthly:
            return calendar.date(byAdding: .month, value: 1, to: date)!
        case .quarterly:
            return calendar.date(byAdding: .month, value: 3, to: date)!
        case .yearly:
            return calendar.date(byAdding: .year, value: 1, to: date)!
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
        case .yearly:
            return amount / 12
        }
    }
}
