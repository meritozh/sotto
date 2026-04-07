import Foundation
import SwiftData

enum PaymentMethodType: String, Codable, CaseIterable {
    case credit
    case debit
    case bank
    case other
}

@Model
final class PaymentMethod {
    @Attribute(.unique) var id: UUID
    var name: String
    var type: PaymentMethodType
    @Relationship(deleteRule: .nullify, inverse: \Subscription.paymentMethod)
    var subscriptions: [Subscription]

    init(name: String, type: PaymentMethodType) {
        self.id = UUID()
        self.name = name
        self.type = type
        self.subscriptions = []
    }
}
