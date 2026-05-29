import SwiftUI
import SwiftData
import TipKit
import SottoKit

@main
struct SottoApp: App {
    let modelContainer: ModelContainer

    @MainActor
    init() {
        do {
            modelContainer = try SottoModelContainerFactory.makeCloudBackedContainer()
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }

        try? Tips.configure([
            .displayFrequency(.immediate),
            .datastoreLocation(.applicationDefault),
        ])
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(modelContainer)
    }
}
