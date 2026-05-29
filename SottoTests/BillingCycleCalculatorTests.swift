import Testing
import Foundation
@testable import SottoKit

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

    // MARK: - cyclesPaid

    @Test func cyclesPaidSameDayCountsFirstPayment() {
        let start = calendar.date(from: DateComponents(year: 2026, month: 4, day: 8))!
        let count = BillingCycleCalculator.cyclesPaid(from: start, asOf: start, cycle: .monthly)
        #expect(count == 1)
    }

    @Test func cyclesPaidFutureStartReturnsZero() {
        let start = calendar.date(from: DateComponents(year: 2026, month: 6, day: 1))!
        let asOf = calendar.date(from: DateComponents(year: 2026, month: 5, day: 9))!
        let count = BillingCycleCalculator.cyclesPaid(from: start, asOf: asOf, cycle: .monthly)
        #expect(count == 0)
    }

    @Test func cyclesPaidMonthlyAfterOneFullMonth() {
        // Apr 8 → May 9: one full calendar month elapsed → 2 payments billed.
        let start = calendar.date(from: DateComponents(year: 2026, month: 4, day: 8))!
        let asOf = calendar.date(from: DateComponents(year: 2026, month: 5, day: 9))!
        let count = BillingCycleCalculator.cyclesPaid(from: start, asOf: asOf, cycle: .monthly)
        #expect(count == 2)
    }

    @Test func cyclesPaidMonthlyJustBeforeAnniversaryStillOne() {
        // Apr 8 → May 7: 29 days, calendar-month delta is 0 → still 1 payment.
        let start = calendar.date(from: DateComponents(year: 2026, month: 4, day: 8))!
        let asOf = calendar.date(from: DateComponents(year: 2026, month: 5, day: 7))!
        let count = BillingCycleCalculator.cyclesPaid(from: start, asOf: asOf, cycle: .monthly)
        #expect(count == 1)
    }

    @Test func cyclesPaidWeeklyAfterFourteenDays() {
        let start = calendar.date(from: DateComponents(year: 2026, month: 4, day: 1))!
        let asOf = calendar.date(from: DateComponents(year: 2026, month: 4, day: 15))!
        let count = BillingCycleCalculator.cyclesPaid(from: start, asOf: asOf, cycle: .weekly)
        #expect(count == 3) // Apr 1, 8, 15
    }

    @Test func cyclesPaidYearlyAfterOneYear() {
        let start = calendar.date(from: DateComponents(year: 2025, month: 5, day: 1))!
        let asOf = calendar.date(from: DateComponents(year: 2026, month: 5, day: 1))!
        let count = BillingCycleCalculator.cyclesPaid(from: start, asOf: asOf, cycle: .yearly)
        #expect(count == 2)
    }

    @Test func cyclesPaidQuarterlyAfterSixMonths() {
        let start = calendar.date(from: DateComponents(year: 2026, month: 1, day: 1))!
        let asOf = calendar.date(from: DateComponents(year: 2026, month: 7, day: 1))!
        let count = BillingCycleCalculator.cyclesPaid(from: start, asOf: asOf, cycle: .quarterly)
        #expect(count == 3) // Jan 1, Apr 1, Jul 1
    }
}
