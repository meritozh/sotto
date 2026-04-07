import Foundation
import SwiftData

@Model
final class ExchangeRate {
    @Attribute(.unique) var baseCurrency: String
    var rates: [String: Double]
    var lastUpdated: Date

    init(baseCurrency: String, rates: [String: Double]) {
        self.baseCurrency = baseCurrency
        self.rates = rates
        self.lastUpdated = Date()
    }

    var isStale: Bool {
        Date().timeIntervalSince(lastUpdated) > 24 * 60 * 60
    }
}
