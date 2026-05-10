import SwiftUI
import SwiftData
import CoreData
import TipKit

@main
struct SottoApp: App {
    let modelContainer: ModelContainer

    init() {
        do {
            let schema = Schema(versionedSchema: SottoSchemaV1.self)
            let configuration = ModelConfiguration(
                schema: schema,
                cloudKitDatabase: .private("iCloud.com.meritozh.sotto")
            )
            modelContainer = try ModelContainer(
                for: schema,
                migrationPlan: SottoMigrationPlan.self,
                configurations: configuration
            )
            CategorySeeder.start(container: modelContainer)
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

// MARK: - Versioned Schema

enum SottoSchemaV1: VersionedSchema {
    static let versionIdentifier = Schema.Version(1, 0, 0)

    static var models: [any PersistentModel.Type] {
        [
            Subscription.self,
            Category.self,
            PaymentMethod.self,
            PaymentHistory.self,
            ExchangeRate.self,
        ]
    }
}

enum SottoMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] { [SottoSchemaV1.self] }
    static var stages: [MigrationStage] { [] }
}

// MARK: - Category Seeding
//
// CloudKit can deliver the same default seed from another device after sync, so we
// defer seeding until either the first CloudKit import finishes or a short fallback
// elapses for users with no iCloud account. We then reconcile by name so concurrent
// first-launch seeds on multiple devices collapse to a single record per default.

@MainActor
enum CategorySeeder {
    private static let didReconcileKey = "Sotto.didReconcileDefaultCategories"
    private static var observer: NSObjectProtocol?

    static func start(container: ModelContainer) {
        guard !UserDefaults.standard.bool(forKey: didReconcileKey) else { return }

        observer = NotificationCenter.default.addObserver(
            forName: NSPersistentCloudKitContainer.eventChangedNotification,
            object: nil,
            queue: .main
        ) { notification in
            guard
                let event = notification.userInfo?[NSPersistentCloudKitContainer.eventNotificationUserInfoKey]
                    as? NSPersistentCloudKitContainer.Event,
                event.type == .import,
                event.endDate != nil
            else { return }
            Task { @MainActor in reconcile(container: container) }
        }

        Task { @MainActor in
            try? await Task.sleep(for: .seconds(5))
            reconcile(container: container)
        }
    }

    private static func reconcile(container: ModelContainer) {
        guard !UserDefaults.standard.bool(forKey: didReconcileKey) else { return }
        let context = container.mainContext

        let existing = (try? context.fetch(FetchDescriptor<Category>())) ?? []
        let grouped = Dictionary(grouping: existing, by: { $0.name })
        let defaultNames = Set(Category.defaults.map(\.name))

        for (name, dupes) in grouped where defaultNames.contains(name) && dupes.count > 1 {
            let keeper = dupes.min(by: { $0.id.uuidString < $1.id.uuidString })!
            for dupe in dupes where dupe !== keeper {
                for sub in (dupe.subscriptions ?? []) {
                    sub.category = keeper
                }
                context.delete(dupe)
            }
        }

        let presentNames = Set(grouped.keys)
        for item in Category.defaults where !presentNames.contains(item.name) {
            context.insert(Category(name: item.name, colorHex: item.colorHex, icon: item.icon))
        }

        try? context.save()
        UserDefaults.standard.set(true, forKey: didReconcileKey)

        if let observer { NotificationCenter.default.removeObserver(observer) }
        observer = nil
    }
}
