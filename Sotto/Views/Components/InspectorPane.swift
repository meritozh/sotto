import SwiftUI
import SwiftData

struct InspectorPane: View {

    // MARK: - Properties

    @Bindable var subscription: Subscription
    @State private var showEditSheet = false
    @State private var showDeleteAlert = false
    var onClose: (() -> Void)?
    /// Invoked after the user confirms deletion in the alert. The parent owns the
    /// model context and selection state, so it must clear the selection before
    /// deleting to avoid the inspector re-rendering against a tombstoned model.
    var onDelete: (() -> Void)?

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
                        Text(subscription.currentDueDate, format: .dateTime.month(.abbreviated).day().year())
                        if subscription.status == .active {
                            Text(subscription.daysUntilDue <= 0 ? "Due today" : "in \(subscription.daysUntilDue) days")
                                .font(.caption)
                                .foregroundStyle(subscription.daysUntilDue <= AppConstants.urgentDaysThreshold ? .red : .secondary)
                        }
                    }
                }
                LabeledContent("Total Spent") {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(subscription.totalCost, format: .currency(code: subscription.currencyCode))
                            .fontWeight(.semibold)
                            .monospacedDigit()
                        Text("since \(subscription.startDate, format: .dateTime.month(.abbreviated).day().year())")
                            .font(.caption)
                            .foregroundStyle(.secondary)
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

                    if onDelete != nil {
                        Button(role: .destructive) {
                            showDeleteAlert = true
                        } label: {
                            Label("Delete…", systemImage: "trash")
                                .frame(maxWidth: .infinity)
                        }
                    }
                }
            }
            .padding()
        }
        .sheet(isPresented: $showEditSheet) {
            AddSubscriptionSheet(existingSubscription: subscription)
        }
        .alert("Delete \(subscription.name)?", isPresented: $showDeleteAlert) {
            Button("Delete", role: .destructive) {
                onDelete?()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This permanently removes the subscription from Sotto. This action cannot be undone.")
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

}

#Preview {
    InspectorPane(subscription: makeSampleSubscription())
        .frame(width: 320)
}
