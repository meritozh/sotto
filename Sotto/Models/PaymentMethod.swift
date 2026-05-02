import Foundation
import SwiftData

// MARK: - PaymentMethodType
enum PaymentMethodType: String, Codable, CaseIterable {
    case credit
    case debit
    case bank
    case other
}

// MARK: - PaymentMethod
@Model
final class PaymentMethod {

    // MARK: - Properties
    var id: UUID = UUID()
    var name: String = ""
    var type: PaymentMethodType = PaymentMethodType.other
    @Relationship(deleteRule: .nullify, inverse: \Subscription.paymentMethod)
    var subscriptions: [Subscription]?

    // MARK: - Initialization
    init(name: String, type: PaymentMethodType) {
        self.id = UUID()
        self.name = name
        self.type = type
        self.subscriptions = []
    }
}
