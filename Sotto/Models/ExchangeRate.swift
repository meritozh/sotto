import Foundation
import SwiftData

@Model
final class ExchangeRate {

    // MARK: - Properties
    // Uniqueness on baseCurrency is enforced in CurrencyService via upsert; CloudKit forbids @Attribute(.unique).
    var baseCurrency: String = "USD"
    var rates: [String: Double] = [:]
    var lastUpdated: Date = Date.distantPast

    // MARK: - Initialization
    init(baseCurrency: String, rates: [String: Double]) {
        self.baseCurrency = baseCurrency
        self.rates = rates
        self.lastUpdated = Date()
    }

    // MARK: - Computed Properties
    var isStale: Bool {
        Date().timeIntervalSince(lastUpdated) > AppConstants.rateStalenessSeconds
    }

    // MARK: - Methods
    /// Convert an amount from `sourceCurrency` to this rate's `baseCurrency`.
    /// Rates are stored as: 1 baseCurrency = rates[target] targetCurrency.
    /// So to convert FROM target TO base: amount / rates[target].
    func convertToBase(amount: Decimal, from sourceCurrency: String) -> Decimal {
        if sourceCurrency == baseCurrency { return amount }
        guard let rate = rates[sourceCurrency], rate > 0 else { return amount }
        return amount / Decimal(rate)
    }
}
