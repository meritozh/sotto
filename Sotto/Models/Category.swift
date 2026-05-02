import Foundation
import SwiftData

@Model
final class Category {

    // MARK: - Properties
    var id: UUID = UUID()
    var name: String = ""
    var colorHex: String = "#B0B0B0"
    var icon: String = "tag"
    @Relationship(deleteRule: .nullify, inverse: \Subscription.category)
    var subscriptions: [Subscription]?

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
        ("Streaming", "#1CD05A", "play.tv"),
        ("Software", "#4ECDC4", "laptopcomputer"),
        ("Cloud Storage", "#5AC8FA", "cloud"),
        ("Gaming", "#96CEB4", "gamecontroller"),
        ("News & Media", "#FB7299", "newspaper"),
        ("Utilities", "#DDA0DD", "bolt"),
        ("Health & Fitness", "#98D8C8", "heart"),
        ("Other", "#B0B0B0", "ellipsis.circle")
    ]
}
