import Foundation
import SwiftData

@MainActor
@Observable
final class CurrencyService {
    private let modelContext: ModelContext
    private(set) var isLoading = false
    private(set) var lastError: String?

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func convert(amount: Decimal, from sourceCurrency: String, to targetCurrency: String) async -> Decimal {
        if sourceCurrency == targetCurrency { return amount }
        guard let rate = await getRate(from: sourceCurrency, to: targetCurrency) else {
            return amount
        }
        return amount * Decimal(rate)
    }

    func refreshRatesIfNeeded(baseCurrency: String) async {
        let cached = fetchCachedRate(baseCurrency: baseCurrency)
        if let cached, !cached.isStale {
            return
        }
        await fetchRates(baseCurrency: baseCurrency)
    }

    private func getRate(from source: String, to target: String) async -> Double? {
        if let cached = fetchCachedRate(baseCurrency: source), let rate = cached.rates[target] {
            return rate
        }
        await fetchRates(baseCurrency: source)
        return fetchCachedRate(baseCurrency: source)?.rates[target]
    }

    private func fetchCachedRate(baseCurrency: String) -> ExchangeRate? {
        let descriptor = FetchDescriptor<ExchangeRate>(
            predicate: #Predicate { $0.baseCurrency == baseCurrency }
        )
        return try? modelContext.fetch(descriptor).first
    }

    private func fetchRates(baseCurrency: String) async {
        isLoading = true
        lastError = nil
        defer { isLoading = false }

        guard let url = URL(string: "https://api.frankfurter.app/latest?from=\(baseCurrency)") else {
            lastError = "Invalid currency code"
            return
        }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try JSONDecoder().decode(FrankfurterResponse.self, from: data)

            if let existing = fetchCachedRate(baseCurrency: baseCurrency) {
                existing.rates = response.rates
                existing.lastUpdated = Date()
            } else {
                let rate = ExchangeRate(baseCurrency: baseCurrency, rates: response.rates)
                modelContext.insert(rate)
            }
            try modelContext.save()
        } catch {
            lastError = "Failed to fetch rates: \(error.localizedDescription)"
        }
    }
}

private struct FrankfurterResponse: Decodable {
    let rates: [String: Double]
}
