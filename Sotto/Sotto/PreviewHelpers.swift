import Foundation
import SwiftData

@MainActor
func makePreviewContainer() -> ModelContainer {
    let schema = Schema([
        Subscription.self,
        Category.self,
        PaymentMethod.self,
        PaymentHistory.self,
        ExchangeRate.self,
    ])
    let container = try! ModelContainer(
        for: schema,
        configurations: ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
    )

    let software = Category(name: "Software", colorHex: "#4ECDC4", icon: "laptopcomputer")
    let streaming = Category(name: "Streaming", colorHex: "#FF6B6B", icon: "play.tv")
    container.mainContext.insert(software)
    container.mainContext.insert(streaming)

    let card = PaymentMethod(name: "Chase Visa", type: .credit)
    container.mainContext.insert(card)

    let claude = Subscription(
        name: "Claude Max",
        icon: "laptopcomputer",
        amount: 125,
        currencyCode: "USD",
        billingCycle: .monthly,
        startDate: .now,
        nextDueDate: Calendar.current.date(byAdding: .day, value: 44, to: .now)!,
        category: software,
        paymentMethod: card,
        notes: "through Apple US account"
    )
    let netflix = Subscription(
        name: "Netflix",
        icon: "play.tv",
        amount: Decimal(string: "15.99")!,
        currencyCode: "USD",
        billingCycle: .monthly,
        startDate: .now,
        nextDueDate: Calendar.current.date(byAdding: .day, value: 7, to: .now)!,
        category: streaming
    )
    container.mainContext.insert(claude)
    container.mainContext.insert(netflix)

    let payment = PaymentHistory(
        subscription: claude,
        paidDate: Calendar.current.date(byAdding: .month, value: -1, to: .now)!,
        amount: 125,
        currencyCode: "USD"
    )
    container.mainContext.insert(payment)

    return container
}

func makeSampleSubscription(
    name: String = "Claude Max",
    icon: String = "laptopcomputer",
    amount: Decimal = 125,
    currencyCode: String = "USD",
    billingCycle: BillingCycle = .monthly,
    daysUntilDue: Int = 44
) -> Subscription {
    Subscription(
        name: name,
        icon: icon,
        amount: amount,
        currencyCode: currencyCode,
        billingCycle: billingCycle,
        startDate: .now,
        nextDueDate: Calendar.current.date(byAdding: .day, value: daysUntilDue, to: .now)!
    )
}

func makeSampleSubscriptions() -> [Subscription] {
    [
        makeSampleSubscription(),
        makeSampleSubscription(name: "Netflix", icon: "play.tv", amount: 16, daysUntilDue: 7),
        makeSampleSubscription(name: "Spotify", icon: "music.note", amount: 10, billingCycle: .yearly, daysUntilDue: 120),
    ]
}
