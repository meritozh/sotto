import SwiftUI
import SwiftData

struct SettingsView: View {

    // MARK: - Properties

    @AppStorage(AppConstants.currencyStorageKey) private var baseCurrency = "USD"
    @Query private var exchangeRates: [ExchangeRate]
    @Query private var paymentMethods: [PaymentMethod]
    @Environment(\.modelContext) private var modelContext
    @State private var isRefreshingRates = false
    @State private var showAddPaymentMethod = false

    // MARK: - Computed Properties

    private var cachedRate: ExchangeRate? {
        exchangeRates.first { $0.baseCurrency == baseCurrency }
    }

    // MARK: - Body

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

            Section("Payment Methods") {
                if paymentMethods.isEmpty {
                    Text("No payment methods yet")
                        .foregroundStyle(.secondary)
                }
                ForEach(paymentMethods) { method in
                    HStack {
                        Image(systemName: iconForType(method.type))
                        Text(method.name)
                        Spacer()
                        Text(method.type.rawValue.capitalized)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .contextMenu {
                        Button("Delete", role: .destructive) {
                            modelContext.delete(method)
                        }
                    }
                }

                Button {
                    showAddPaymentMethod = true
                } label: {
                    Label("Add Payment Method", systemImage: "plus")
                }
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
        .sheet(isPresented: $showAddPaymentMethod) {
            PaymentMethodForm(isPresented: $showAddPaymentMethod) { method in
                modelContext.insert(method)
            }
        }
    }

    // MARK: - Helpers

    private func iconForType(_ type: PaymentMethodType) -> String {
        switch type {
        case .credit: "creditcard"
        case .debit: "creditcard.fill"
        case .bank: "building.columns"
        case .other: "ellipsis.circle"
        }
    }
}
