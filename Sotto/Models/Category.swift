import Foundation
import SwiftData

@Model
final class Category {

    // MARK: - Properties
    @Attribute(.unique) var id: UUID
    var name: String
    var colorHex: String
    var icon: String
    @Relationship(deleteRule: .nullify, inverse: \Subscription.category)
    var subscriptions: [Subscription]

    // MARK: - Initialization
    init(name: String, colorHex: String, icon: String) {
        self.id = UUID()
        self.name = name
        self.colorHex = colorHex
        self.icon = icon
        self.subscriptions = []
    }

    // MARK: - Static
    static let defaults: [(name: String, colorHex: String, icon: String)] = [
        ("Streaming", "#FF6B6B", "play.tv"),
        ("Software", "#4ECDC4", "laptopcomputer"),
        ("Cloud Storage", "#45B7D1", "cloud"),
        ("Gaming", "#96CEB4", "gamecontroller"),
        ("News & Media", "#FFEAA7", "newspaper"),
        ("Utilities", "#DDA0DD", "bolt"),
        ("Health & Fitness", "#98D8C8", "heart"),
        ("Other", "#B0B0B0", "ellipsis.circle")
    ]
}
