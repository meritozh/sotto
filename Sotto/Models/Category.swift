import Foundation
import SwiftData

@Model
final class Category {

    // MARK: - Properties
    var id: UUID = UUID()
    var name: String = ""
    var nameEnglish: String = ""
    var nameChineseSimplified: String = ""
    var colorHex: String = "#B0B0B0"
    var icon: String = "tag"
    @Relationship(deleteRule: .nullify, inverse: \Subscription.category)
    var subscriptions: [Subscription]?

    // MARK: - Initialization
    init(
        name: String,
        colorHex: String,
        icon: String,
        nameEnglish: String = "",
        nameChineseSimplified: String = ""
    ) {
        self.id = UUID()
        self.name = name
        self.nameEnglish = nameEnglish
        self.nameChineseSimplified = nameChineseSimplified
        self.colorHex = colorHex
        self.icon = icon
        self.subscriptions = []
    }

    func localizedName(for locale: Locale) -> String {
        let englishName = nameEnglish.categoryTrimmed
        let chineseName = nameChineseSimplified.categoryTrimmed

        if locale.categoryPrefersChinese {
            if !chineseName.isEmpty { return chineseName }
            if !englishName.isEmpty { return englishName }
        } else {
            if !englishName.isEmpty { return englishName }
            if !chineseName.isEmpty { return chineseName }
        }

        if let defaultDisplayName {
            return locale.categoryPrefersChinese
                ? defaultDisplayName.chineseSimplified
                : defaultDisplayName.english
        }

        return name
    }

    static func canonicalName(english: String, chineseSimplified: String) -> String {
        let englishName = english.categoryTrimmed
        let chineseName = chineseSimplified.categoryTrimmed

        return englishName.isEmpty ? chineseName : englishName
    }

    var hasDefaultLocalizedName: Bool {
        defaultDisplayName != nil
    }

    var hasLocalizedNameOverrides: Bool {
        !nameEnglish.categoryTrimmed.isEmpty || !nameChineseSimplified.categoryTrimmed.isEmpty
    }

    private var defaultDisplayName: (english: String, chineseSimplified: String)? {
        switch name {
        case "Streaming": return ("Streaming", "流媒体")
        case "Software": return ("Software", "软件")
        case "Cloud Storage": return ("Cloud Storage", "云存储")
        case "Gaming": return ("Gaming", "游戏")
        case "News & Media": return ("News & Media", "新闻与媒体")
        case "Utilities": return ("Utilities", "工具")
        case "Health & Fitness": return ("Health & Fitness", "健康与健身")
        case "Other": return ("Other", "其他")
        default: return nil
        }
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

private extension String {
    var categoryTrimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

private extension Locale {
    var categoryPrefersChinese: Bool {
        identifier.lowercased().hasPrefix("zh")
    }
}
