import Foundation
import SwiftData

@Model
final class PaymentHistory {

    // MARK: - Properties
    @Attribute(.unique) var id: UUID
    var subscription: Subscription?
    var paidDate: Date
    var amount: Decimal
    var currencyCode: String

    // MARK: - Initialization
    init(subscription: Subscription, paidDate: Date, amount: Decimal, currencyCode: String) {
        self.id = UUID()
        self.subscription = subscription
        self.paidDate = paidDate
        self.amount = amount
        self.currencyCode = currencyCode
    }
}
