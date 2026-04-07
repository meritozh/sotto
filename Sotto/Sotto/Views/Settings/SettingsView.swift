import SwiftUI
import SwiftData

struct SettingsView: View {
    @AppStorage("baseCurrency") private var baseCurrency = "USD"
    @Query private var exchangeRates: [ExchangeRate]
    @Environment(\.modelContext) private var modelContext
    @State private var isRefreshingRates = false

    private var cachedRate: ExchangeRate? {
        exchangeRates.first { $0.baseCurrency == baseCurrency }
    }

    var body: some View {
        Form {
            Section("Currency") {
                CurrencyPicker(selectedCurrency: $baseCurrency)

                if let rate = cachedRate {
                    LabeledContent("Exchange Rates") {
                        VStack(alignment: .trailing) {
                            Text("Last updated: \(rate.lastUpdated, format: .dateTime)")
                                .font(.caption)
                                .foregroundStyle(rate.isStale ? .red : .secondary)
                            if rate.isStale {
                                Text("Rates may be outdated")
                                    .font(.caption)
                                    .foregroundStyle(.red)
                            }
                        }
                    }
                }

                Button {
                    Task {
                        isRefreshingRates = true
                        let service = CurrencyService(modelContext: modelContext)
                        await service.refreshRatesIfNeeded(baseCurrency: baseCurrency)
                        isRefreshingRates = false
                    }
                } label: {
                    HStack {
                        Label("Refresh Exchange Rates", systemImage: "arrow.clockwise")
                        if isRefreshingRates {
                            ProgressView()
                                .controlSize(.small)
                        }
                    }
                }
                .disabled(isRefreshingRates)
            }

            Section("About") {
                LabeledContent("Version") {
                    Text("1.0.0")
                }
                LabeledContent("Platform") {
                    Text("macOS")
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Settings")
    }
}
