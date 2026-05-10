import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct SettingsView: View {

    // MARK: - Properties

    @AppStorage(AppConstants.currencyStorageKey) private var baseCurrency = "USD"
    @Query private var exchangeRates: [ExchangeRate]
    @Query private var paymentMethods: [PaymentMethod]
    @Environment(\.modelContext) private var modelContext
    @State private var isRefreshingRates = false
    @State private var showAddPaymentMethod = false

    @State private var exportDocument: SottoBackupDocument?
    @State private var showExporter = false
    @State private var showImporter = false
    @State private var pendingImport: ExportPayload?
    @State private var importSummary: String?
    @State private var alertMessage: String?

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
                        Text(method.type.displayName)
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

            Section("Data") {
                Button {
                    prepareExport()
                } label: {
                    Label("Export Data…", systemImage: "square.and.arrow.up")
                }

                Button {
                    showImporter = true
                } label: {
                    Label("Import Data…", systemImage: "square.and.arrow.down")
                }

                Text("Export creates a JSON backup of all subscriptions, categories, payment methods, and payment history. Import lets you restore that backup into this app.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("About") {
                LabeledContent("Version") {
                    Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—")
                }
                LabeledContent("Platform") {
                    #if os(iOS)
                    Text("iOS")
                    #elseif os(macOS)
                    Text("macOS")
                    #else
                    Text("Apple")
                    #endif
                }
            }
        }
        .formStyle(.grouped)
        .scrollContentBackground(.hidden)
        .background(DesignTokens.windowBackground)
        #if os(iOS)
        // iOS 26 floating tab bar overlays the bottom of the form, so push content up
        // far enough that the last row clears the pill instead of hiding behind it.
        .safeAreaPadding(.bottom, 64)
        #endif
        .navigationTitle("Settings")
        .sheet(isPresented: $showAddPaymentMethod) {
            PaymentMethodForm(isPresented: $showAddPaymentMethod) { method in
                modelContext.insert(method)
            }
        }
        .fileExporter(
            isPresented: $showExporter,
            document: exportDocument,
            contentType: .json,
            defaultFilename: defaultExportFilename()
        ) { result in
            if case .failure(let error) = result {
                alertMessage = String(localized: "Export failed: \(error.localizedDescription)")
            }
            exportDocument = nil
        }
        .fileImporter(
            isPresented: $showImporter,
            allowedContentTypes: [.json]
        ) { result in
            handleImportPick(result)
        }
        .confirmationDialog(
            importSummary ?? String(localized: "Import data?"),
            isPresented: Binding(
                get: { pendingImport != nil },
                set: { if !$0 { pendingImport = nil } }
            ),
            titleVisibility: .visible,
            presenting: pendingImport
        ) { payload in
            Button("Replace All", role: .destructive) {
                performImport(payload, mode: .replace)
            }
            Button("Merge (keep existing)") {
                performImport(payload, mode: .merge)
            }
            Button("Cancel", role: .cancel) {
                pendingImport = nil
            }
        } message: { _ in
            Text("Replace All deletes existing data first. Merge keeps existing records and only adds new ones.")
        }
        .alert(
            "Sotto",
            isPresented: Binding(
                get: { alertMessage != nil },
                set: { if !$0 { alertMessage = nil } }
            ),
            presenting: alertMessage
        ) { _ in
            Button("OK", role: .cancel) { alertMessage = nil }
        } message: { msg in
            Text(msg)
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

    private func prepareExport() {
        do {
            let data = try DataExportService.encodedSnapshot(from: modelContext)
            exportDocument = SottoBackupDocument(data: data)
            showExporter = true
        } catch {
            alertMessage = String(localized: "Export failed: \(error.localizedDescription)")
        }
    }

    private func handleImportPick(_ result: Result<URL, Error>) {
        switch result {
        case .success(let url):
            let needsScope = url.startAccessingSecurityScopedResource()
            defer {
                if needsScope { url.stopAccessingSecurityScopedResource() }
            }
            do {
                let data = try Data(contentsOf: url)
                let payload = try DataExportService.decode(data)
                importSummary = String(localized: "\(payload.subscriptions.count) subscriptions, \(payload.categories.count) categories, \(payload.paymentMethods.count) payment methods, \(payload.paymentHistory.count) payment records")
                pendingImport = payload
            } catch {
                alertMessage = String(localized: "Import failed: \(error.localizedDescription)")
            }
        case .failure(let error):
            alertMessage = String(localized: "Import failed: \(error.localizedDescription)")
        }
    }

    private func performImport(_ payload: ExportPayload, mode: DataExportService.ImportMode) {
        do {
            try DataExportService.restore(payload, into: modelContext, mode: mode)
            alertMessage = mode == .replace
                ? String(localized: "Data replaced successfully.")
                : String(localized: "Data merged successfully.")
        } catch {
            alertMessage = String(localized: "Import failed: \(error.localizedDescription)")
        }
        pendingImport = nil
    }

    private func defaultExportFilename() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return "Sotto-Backup-\(formatter.string(from: Date()))"
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
    .modelContainer(makePreviewContainer())
}
