import SwiftUI
import SwiftData
import TipKit

struct AddSubscriptionSheet: View {

    // MARK: - Properties

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.locale) private var locale
    @Query private var categories: [Category]
    @Query private var paymentMethods: [PaymentMethod]

    var existingSubscription: Subscription?

    @State private var name = ""
    @State private var icon = "ellipsis.circle"
    @State private var amount = ""
    @State private var currencyCode = "USD"
    @State private var billingCycle = BillingCycle.monthly
    @State private var startDate = Date()
    @State private var selectedCategory: Category?
    @State private var selectedPaymentMethod: PaymentMethod?
    @State private var notes = ""
    @State private var showIconPicker = false

    // MARK: - Computed Properties

    private var isValid: Bool {
        !name.isEmpty && Decimal(string: amount) != nil && selectedCategory != nil
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            formContent
                .navigationTitle(existingSubscription == nil ? "New Subscription" : "Edit Subscription")
                #if os(iOS)
                .navigationBarTitleDisplayMode(.inline)
                #endif
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { dismiss() }
                            .keyboardShortcut(.cancelAction)
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") { save() }
                            .keyboardShortcut(.defaultAction)
                            .disabled(!isValid)
                    }
                }
        }
        #if os(macOS)
        .frame(width: 480, height: 520)
        #endif
        .onAppear { populateForEdit() }
    }

    // MARK: - Helpers

    private var formContent: some View {
        Form {
            Section("Details") {
                HStack {
                    Button {
                        showIconPicker = true
                    } label: {
                        Image(systemName: icon)
                            .font(.title)
                            .frame(width: 44, height: 44)
                    }
                    .glassActionButtonStyle()
                    #if os(macOS)
                    .popover(isPresented: $showIconPicker) {
                        IconPicker(selectedIcon: $icon)
                    }
                    #endif

                    TextField("Subscription Name", text: $name)
                        #if os(macOS)
                        .textFieldStyle(.roundedBorder)
                        #endif
                }

                #if os(macOS)
                HStack {
                    amountField
                        .frame(width: 120)
                    CurrencyPicker(selectedCurrency: $currencyCode)
                }
                #else
                amountField
                CurrencyPicker(selectedCurrency: $currencyCode)
                #endif

                Picker("Billing Cycle", selection: $billingCycle) {
                    ForEach(BillingCycle.allCases, id: \.self) { cycle in
                        Text(cycle.displayName).tag(cycle)
                    }
                }

                DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
            }

            Section("Organization") {
                Picker("Category", selection: $selectedCategory) {
                    Text("None").tag(nil as Category?)
                    ForEach(categories) { category in
                        Label {
                            Text(category.localizedName(for: locale))
                        } icon: {
                            Image(systemName: category.icon)
                        }
                            .tag(category as Category?)
                    }
                }

                Picker("Payment Method", selection: $selectedPaymentMethod) {
                    Text("None").tag(nil as PaymentMethod?)
                    ForEach(paymentMethods) { method in
                        Text(method.name).tag(method as PaymentMethod?)
                    }
                }
            }

            Section("Notes") {
                TextEditor(text: $notes)
                    .frame(height: 60)
            }
        }
        .formStyle(.grouped)
        #if os(iOS)
        .sheet(isPresented: $showIconPicker) {
            IconPicker(selectedIcon: $icon)
        }
        #endif
    }

    private var amountField: some View {
        TextField("Amount", text: $amount)
            #if os(macOS)
            .textFieldStyle(.roundedBorder)
            #else
            .keyboardType(.decimalPad)
            #endif
    }

    private func populateForEdit() {
        guard let sub = existingSubscription else { return }
        name = sub.name
        icon = sub.icon
        amount = "\(sub.amount)"
        currencyCode = sub.currencyCode
        billingCycle = sub.billingCycle
        startDate = sub.startDate
        selectedCategory = sub.category
        selectedPaymentMethod = sub.paymentMethod
        notes = sub.notes ?? ""
    }

    private func save() {
        guard let decimalAmount = Decimal(string: amount) else { return }

        if let existing = existingSubscription {
            existing.name = name
            existing.icon = icon
            existing.amount = decimalAmount
            existing.currencyCode = currencyCode
            existing.billingCycle = billingCycle
            existing.startDate = startDate
            existing.nextDueDate = nextDueDate(for: startDate, cycle: billingCycle)
            existing.category = selectedCategory
            existing.paymentMethod = selectedPaymentMethod
            existing.notes = notes.isEmpty ? nil : notes
            existing.updatedAt = Date()
        } else {
            let subscription = Subscription(
                name: name,
                icon: icon,
                amount: decimalAmount,
                currencyCode: currencyCode,
                billingCycle: billingCycle,
                startDate: startDate,
                nextDueDate: nextDueDate(for: startDate, cycle: billingCycle),
                category: selectedCategory,
                paymentMethod: selectedPaymentMethod,
                notes: notes.isEmpty ? nil : notes
            )
            modelContext.insert(subscription)
            AddFirstSubscriptionTip().invalidate(reason: .actionPerformed)
        }

        dismiss()
    }

    /// For new subscriptions, the start date is the first due date.
    /// If the start date is in the past, advance until we find the next future due date.
    private func nextDueDate(for start: Date, cycle: BillingCycle) -> Date {
        var due = start
        let today = Calendar.current.startOfDay(for: Date())
        while due < today {
            due = BillingCycleCalculator.nextDueDate(from: due, cycle: cycle)
        }
        return due
    }
}

#Preview("New") {
    AddSubscriptionSheet()
        .modelContainer(makePreviewContainer())
}

#Preview("Edit") {
    AddSubscriptionSheet(existingSubscription: makeSampleSubscription())
        .modelContainer(makePreviewContainer())
}
