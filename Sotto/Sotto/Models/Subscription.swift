import Foundation
import SwiftData

enum BillingCycle: String, Codable, CaseIterable {
    case weekly
    case monthly
    case quarterly
    case yearly

    var displayName: String {
        rawValue.capitalized
    }
}

enum SubscriptionStatus: String, Codable, CaseIterable {
    case active
    case paused
    case cancelled

    var displayName: String {
        rawValue.capitalized
    }
}

@Model
final class Subscription {
    @Attribute(.unique) var id: UUID
    var name: String
    var icon: String
    var amount: Decimal
    var currencyCode: String
    var billingCycle: BillingCycle
    var startDate: Date
    var nextDueDate: Date
    var category: Category?
    var paymentMethod: PaymentMethod?
    var status: SubscriptionStatus
    var notes: String?
    var createdAt: Date
    var updatedAt: Date
    @Relationship(deleteRule: .cascade, inverse: \PaymentHistory.subscription)
    var paymentHistory: [PaymentHistory]

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
