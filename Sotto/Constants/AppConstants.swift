import Foundation

enum AppConstants {
    static let urgentDaysThreshold = 3
    static let rateStalenessSeconds: TimeInterval = 86_400
    static let overlayAnimationDuration: TimeInterval = 0.25
    static let currencyStorageKey = "baseCurrency"
}

enum DesignTokens {
    static let cardCornerRadius: CGFloat = 12
    static let cardShadowRadius: CGFloat = 2
    static let cardShadowOffsetY: CGFloat = 1
    static let cardShadowOpacity: Double = 0.05
}
