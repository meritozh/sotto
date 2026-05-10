import Foundation
import SwiftData

// MARK: - BillingCycle
enum BillingCycle: String, Codable, CaseIterable {
    case weekly
    case monthly
    case quarterly
    case halfYearly
    case yearly

    var displayName: LocalizedStringResource {
        switch self {
        case .weekly: "Weekly"
        case .monthly: "Monthly"
        case .quarterly: "Quarterly"
        case .halfYearly: "Half-Yearly"
        case .yearly: "Yearly"
        }
    }
}

// MARK: - SubscriptionStatus
enum SubscriptionStatus: String, Codable, CaseIterable {
    case active
    case paused
    case cancelled

    var displayName: LocalizedStringResource {
        switch self {
        case .active: "Active"
        case .paused: "Paused"
        case .cancelled: "Cancelled"
        }
    }
}

// MARK: - Subscription
@Model
final class Subscription {

    // MARK: - Properties
    // CloudKit requires every attribute to be optional or have a default; uniqueness is unsupported.
    var id: UUID = UUID()
    var name: String = ""
    var icon: String = ""
    var amount: Decimal = 0
    var currencyCode: String = "USD"
    var billingCycle: BillingCycle = BillingCycle.monthly
    var startDate: Date = Date.distantPast
    var nextDueDate: Date = Date.distantPast
    var category: Category?
    var paymentMethod: PaymentMethod?
    var status: SubscriptionStatus = SubscriptionStatus.active
    var notes: String?
    var createdAt: Date = Date.distantPast
    var updatedAt: Date = Date.distantPast
    @Relationship(deleteRule: .cascade, inverse: \PaymentHistory.subscription)
    var paymentHistory: [PaymentHistory]?

    // MARK: - Initialization
    init(
        name: String,
        icon: String,
        amount: Decimal,
        currencyCode: String,
        billingCycle: BillingCycle,
        startDate: Date,
        nextDueDate: Date,
        category: Category? = nil,
        paymentMethod: PaymentMethod? = nil,
        status: SubscriptionStatus = .active,
        notes: String? = nil
    ) {
        self.id = UUID()
        self.name = name
        self.icon = icon
        self.amount = amount
        self.currencyCode = currencyCode
        self.billingCycle = billingCycle
        self.startDate = startDate
        self.nextDueDate = nextDueDate
        self.category = category
        self.paymentMethod = paymentMethod
        self.status = status
        self.notes = notes
        self.createdAt = Date()
        self.updatedAt = Date()
        self.paymentHistory = []
    }
}
