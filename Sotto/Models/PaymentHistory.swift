import Foundation
import SwiftData

@Model
final class PaymentHistory {

    // MARK: - Properties
    var id: UUID = UUID()
    var subscription: Subscription?
    var paidDate: Date = Date.distantPast
    var amount: Decimal = 0
    var currencyCode: String = "USD"

    // MARK: - Initialization
    init(subscription: Subscription, paidDate: Date, amount: Decimal, currencyCode: String) {
        self.id = UUID()
        self.subscription = subscription
        self.paidDate = paidDate
        self.amount = amount
        self.currencyCode = currencyCode
    }
}
