import Testing
import Foundation
@testable import Sotto

@Suite("BillingCycleCalculator Tests")
struct BillingCycleCalculatorTests {
    let calendar = Calendar.current

    @Test func weeklyAdvancesBySevenDays() {
        let start = calendar.date(from: DateComponents(year: 2026, month: 1, day: 1))!
        let next = BillingCycleCalculator.nextDueDate(from: start, cycle: .weekly)
        let expected = calendar.date(from: DateComponents(year: 2026, month: 1, day: 8))!
        #expect(next == expected)
    }

    @Test func monthlyAdvancesByOneMonth() {
        let start = calendar.date(from: DateComponents(year: 2026, month: 1, day: 15))!
        let next = BillingCycleCalculator.nextDueDate(from: start, cycle: .monthly)
        let expected = calendar.date(from: DateComponents(year: 2026, month: 2, day: 15))!
        #expect(next == expected)
    }

    @Test func quarterlyAdvancesByThreeMonths() {
        let start = calendar.date(from: DateComponents(year: 2026, month: 3, day: 1))!
        let next = BillingCycleCalculator.nextDueDate(from: start, cycle: .quarterly)
        let expected = calendar.date(from: DateComponents(year: 2026, month: 6, day: 1))!
        #expect(next == expected)
    }

    @Test func yearlyAdvancesByOneYear() {
        let start = calendar.date(from: DateComponents(year: 2026, month: 6, day: 15))!
        let next = BillingCycleCalculator.nextDueDate(from: start, cycle: .yearly)
        let expected = calendar.date(from: DateComponents(year: 2027, month: 6, day: 15))!
        #expect(next == expected)
    }

    @Test func monthlyAmountForWeekly() {
        let amount: Decimal = 10
        let monthly = BillingCycleCalculator.monthlyEquivalent(amount: amount, cycle: .weekly)
        // 10 * 52 / 12 ≈ 43.33
        #expect(monthly > 43 && monthly < 44)
    }

    @Test func monthlyAmountForYearly() {
        let amount: Decimal = 120
        let monthly = BillingCycleCalculator.monthlyEquivalent(amount: amount, cycle: .yearly)
        #expect(monthly == 10)
    }
}
