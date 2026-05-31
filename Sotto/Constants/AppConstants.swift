import Foundation
import SwiftUI

public enum AppConstants {
    static let urgentDaysThreshold = 3
    static let soonDaysThreshold = 14
    static let rateStalenessSeconds: TimeInterval = 86_400
    static let overlayAnimationDuration: TimeInterval = 0.25
    static let currencyStorageKey = "baseCurrency"
    public static let languageStorageKey = "preferredLanguageCode"
}

enum DesignTokens {

    // MARK: - Radii (macOS Tahoe)
    static let radiusXS: CGFloat = 5
    static let radiusSM: CGFloat = 7
    static let radiusMD: CGFloat = 9
    static let radiusLG: CGFloat = 12
    static let cardCornerRadius: CGFloat = 12

    // MARK: - Card shadow
    static let cardShadowRadius: CGFloat = 1
    static let cardShadowOffsetY: CGFloat = 1
    static let cardShadowOpacity: Double = 0.025

    // MARK: - Surfaces
    #if os(macOS)
    static let windowBackground = Color(nsColor: .windowBackgroundColor)
    static let sidebarTint = Color(nsColor: .underPageBackgroundColor).opacity(0.65)
    static let contentDivider = Color(nsColor: .separatorColor).opacity(0.45)
    static let cardSurface = Color(nsColor: .controlBackgroundColor).opacity(0.46)
    static let cardBorder = Color(nsColor: .separatorColor).opacity(0.36)
    static let kpiSurface = Color.primary.opacity(0.045)
    #else
    static let windowBackground = Color(uiColor: .systemGroupedBackground)
    static let sidebarTint = Color(uiColor: .systemBackground).opacity(0.65)
    static let contentDivider = Color(uiColor: .separator).opacity(0.5)
    static let cardSurface = Color(uiColor: .secondarySystemGroupedBackground).opacity(0.42)
    static let cardBorder = Color(uiColor: .separator).opacity(0.4)
    static let kpiSurface = Color.primary.opacity(0.045)
    #endif

    // MARK: - Foreground (label hierarchy)
    static let label = Color.primary
    static let label2 = Color.secondary
    static let label3 = Color.secondary.opacity(0.78)
    static let label4 = Color.secondary.opacity(0.52)

    // MARK: - Selection
    static let rowHover = Color.primary.opacity(0.045)
    static let rowSelected = Color.accentColor.opacity(0.14)
    static let accentTint = Color.accentColor.opacity(0.14)

    // MARK: - Semantic colors
    static let dueSoon = Color.orange
    static let dueSoonBg = Color.orange.opacity(0.16)

    // MARK: - Category palette (macOS-style muted)
    static let categoryPalette: [String] = [
        "#34a5d8", // software (blue)
        "#b56bd1", // utilities (purple)
        "#4cc28e", // gaming (green)
        "#e2a64a", // news/media (amber)
        "#ed7878", // cloud (coral)
        "#8a8f99"  // other (slate)
    ]
}

// MARK: - Color light/dark helper

extension Color {
    init(light: Color, dark: Color) {
        #if os(macOS)
        self = Color(nsColor: NSColor(name: nil) { appearance in
            switch appearance.bestMatch(from: [.aqua, .darkAqua]) {
            case .darkAqua: return NSColor(dark)
            default:        return NSColor(light)
            }
        })
        #else
        self = Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark ? UIColor(dark) : UIColor(light)
        })
        #endif
    }
}
