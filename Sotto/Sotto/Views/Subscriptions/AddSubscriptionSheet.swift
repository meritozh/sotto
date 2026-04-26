import SwiftUI
import SwiftData

struct AddSubscriptionSheet: View {

    // MARK: - Properties

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
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
        VStack(spacing: 0) {
            HStack {
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Spacer()
                Text(existingSubscription == nil ? "New Subscription" : "Edit Subscription")
                    .font(.headline)
                Spacer()
                Button("Save") { save() }
                    .keyboardShortcut(.defaultAction)
                    .disabled(!isValid)
            }
            .padding()

            Divider()

            Form {
                Section("Details") {
                    HStack {
                        Button {
                            showIconPicker = true
                        } label: {
                            Image(systemName: icon)
                                .font(.title)
                                .frame(width: 44, height: 44)
                                .background(RoundedRectangle(cornerRadius: 10).fill(.quaternary))
                        }
                        .buttonStyle(.plain)
                        .popover(isPresented: $showIconPicker) {
                            IconPicker(selectedIcon: $icon)
                        }

                        TextField("Subscription Name", text: $name)
                            #if os(macOS)
                            .textFieldStyle(.roundedBorder)
                            #endif
                    }

                    HStack {
                        TextField("Amount", text: $amount)
                            #if os(macOS)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 120)
                            #else
                            .keyboardType(.decimalPad)
                            #endif
                        CurrencyPicker(selectedCurrency: $currencyCode)
                    }

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
                            Label(category.name, systemImage: category.icon)
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
        }
        #if os(macOS)
        .frame(width: 480, height: 520)
        #endif
        .onAppear { populateForEdit() }
    }

    // MARK: - Helpers

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
