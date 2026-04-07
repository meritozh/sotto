import SwiftUI
import SwiftData

@main
struct SottoApp: App {
    let modelContainer: ModelContainer

    init() {
        do {
            modelContainer = try ModelContainer(for:
                Subscription.self,
                Category.self,
                PaymentMethod.self,
                PaymentHistory.self,
                ExchangeRate.self
            )
            SottoApp.seedDefaultCategories(context: modelContainer.mainContext)
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(modelContainer)
    }

    @MainActor
    private static func seedDefaultCategories(context: ModelContext) {
        let descriptor = FetchDescriptor<Category>()
        let existingCount = (try? context.fetchCount(descriptor)) ?? 0
        guard existingCount == 0 else { return }

        for item in Category.defaults {
            let category = Category(name: item.name, colorHex: item.colorHex, icon: item.icon)
            context.insert(category)
        }
    }
}
