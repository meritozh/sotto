import SwiftUI
import SwiftData

@main
struct SottoApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [
            Subscription.self,
            Category.self,
            PaymentMethod.self,
            PaymentHistory.self,
            ExchangeRate.self
        ])
    }
}
