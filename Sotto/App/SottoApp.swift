import SwiftUI
import SwiftData
import TipKit
import SottoKit

@main
struct SottoApp: App {
    @AppStorage(AppConstants.languageStorageKey) private var preferredLanguage = "system"

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

        UserDefaults.standard.removeObject(forKey: "AppleLanguages")
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.locale, appLocale)
        }
        .modelContainer(modelContainer)
    }

    private var appLocale: Locale {
        preferredLanguage == "system" ? .autoupdatingCurrent : Locale(identifier: preferredLanguage)
    }
}
