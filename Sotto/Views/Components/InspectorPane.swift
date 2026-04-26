import SwiftUI
import SwiftData

struct InspectorPane: View {

    // MARK: - Properties

    @Bindable var subscription: Subscription
    @Environment(\.modelContext) private var modelContext
    @State private var showEditSheet = false
    var onClose: (() -> Void)?

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if let onClose {
                    HStack {
                        Spacer()
                        Button {
                            onClose()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title2)
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }

                // Header
                HStack {
                    Image(systemName: subscription.icon)
                        .font(.largeTitle)
                        .frame(width: 48, height: 48)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(subscription.category.map { Color(hex: $0.colorHex).opacity(0.2) } ?? Color.gray.opacity(0.1))
                        )
                    VStack(alignment: .leading) {
                        Text(subscription.name)
                            .font(.title2)
                            .fontWeight(.bold)
                        if let category = subscription.category {
                            Text(category.name)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Divider()

                // Amount & Cycle
                LabeledContent("Amount") {
                    Text(subscription.amount, format: .currency(code: subscription.currencyCode))
                        .fontWeight(.semibold)
                }
                LabeledContent("Billing Cycle") {
                    Text(subscription.billingCycle.displayName)
                }
                LabeledContent("Status") {
                    Text(subscription.status.displayName)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(statusColor.opacity(0.15)))
                        .foregroundStyle(statusColor)
                }
                LabeledContent("Next Due") {
                    VStack(alignment: .trailing) {
                        Text(subscription.nextDueDate, format: .dateTime.month(.abbreviated).day().year())
                        if subscription.status == .active {
                            Text(subscription.daysUntilDue <= 0 ? "Due today" : "in \(subscription.daysUntilDue) days")
                                .font(.caption)
                                .foregroundStyle(subscription.daysUntilDue <= AppConstants.urgentDaysThreshold ? .red : .secondary)
                        }
                    }
                }
                if let method = subscription.paymentMethod {
                    LabeledContent("Payment Method") {
                        Text(method.name)
                    }
                }
                if let notes = subscription.notes, !notes.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Notes")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text(notes)
                            .font(.body)
                    }
                }

                Divider()

                // Quick Actions
                VStack(spacing: 8) {
                    if subscription.status == .active {
                        Button {
                            markAsPaid()
                        } label: {
                            Label("Mark as Paid", systemImage: "checkmark.circle")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                    }

                    HStack(spacing: 8) {
                        if subscription.status == .active {
                            Button {
                                subscription.status = .paused
                                subscription.updatedAt = Date()
                            } label: {
                                Label("Pause", systemImage: "pause.circle")
                                    .frame(maxWidth: .infinity)
                            }
                        }
                        if subscription.status == .paused {
                            Button {
                                subscription.status = .active
                                subscription.updatedAt = Date()
                            } label: {
                                Label("Resume", systemImage: "play.circle")
                                    .frame(maxWidth: .infinity)
                            }
                        }
                        Button {
                            showEditSheet = true
                        } label: {
                            Label("Edit", systemImage: "pencil")
                                .frame(maxWidth: .infinity)
                        }
                    }

                    if subscription.status != .cancelled {
                        Button(role: .destructive) {
                            subscription.status = .cancelled
                            subscription.updatedAt = Date()
                        } label: {
                            Label("Cancel Subscription", systemImage: "xmark.circle")
                                .frame(maxWidth: .infinity)
                        }
                    }
                }

                Divider()

                // Payment History
                paymentHistorySection
            }
            .padding()
        }
        .sheet(isPresented: $showEditSheet) {
            AddSubscriptionSheet(existingSubscription: subscription)
        }
    }

    // MARK: - Computed Properties

    private var statusColor: Color {
        switch subscription.status {
        case .active: .green
        case .paused: .orange
        case .cancelled: .red
        }
    }

    // MARK: - Actions

    private func markAsPaid() {
        let payment = PaymentHistory(
            subscription: subscription,
            paidDate: Date(),
            amount: subscription.amount,
            currencyCode: subscription.currencyCode
        )
        modelContext.insert(payment)
        subscription.nextDueDate = BillingCycleCalculator.nextDueDate(
            from: subscription.nextDueDate,
            cycle: subscription.billingCycle
        )
        subscription.updatedAt = Date()
    }

    // MARK: - Private Views

    private var paymentHistorySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Payment History")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            let sorted = subscription.paymentHistory.sorted { $0.paidDate > $1.paidDate }
            if sorted.isEmpty {
                Text("No payments recorded")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            } else {
                ForEach(sorted) { payment in
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                            .font(.caption)
                        Text(payment.paidDate, format: .dateTime.month(.abbreviated).day().year())
                            .font(.caption)
                        Spacer()
                        Text(payment.amount, format: .currency(code: payment.currencyCode))
                            .font(.caption)
                    }
                }
            }
        }
    }
}

#Preview {
    InspectorPane(subscription: makeSampleSubscription())
        .frame(width: 320)
}
