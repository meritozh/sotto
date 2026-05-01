import Foundation
import SwiftUI

enum AppConstants {
    static let urgentDaysThreshold = 3
    static let soonDaysThreshold = 14
    static let rateStalenessSeconds: TimeInterval = 86_400
    static let overlayAnimationDuration: TimeInterval = 0.25
    static let currencyStorageKey = "baseCurrency"
}

enum DesignTokens {

    // MARK: - Radii (macOS Tahoe)
    static let radiusXS: CGFloat = 5
    static let radiusSM: CGFloat = 7
    static let radiusMD: CGFloat = 9
    static let radiusLG: CGFloat = 12
    static let cardCornerRadius: CGFloat = 12

    // MARK: - Card shadow
    static let cardShadowRadius: CGFloat = 2
    static let cardShadowOffsetY: CGFloat = 1
    static let cardShadowOpacity: Double = 0.05

    // MARK: - Surfaces (warm ivory)
    static let windowBackground = Color(light: Color(hex: "#fbfaf6"), dark: Color(hex: "#1f1d18"))
    static let sidebarTint = Color(light: Color(hex: "#f5f0e4").opacity(0.55), dark: Color(hex: "#28241c").opacity(0.6))
    static let contentDivider = Color(light: Color.black.opacity(0.07), dark: Color.white.opacity(0.07))
    static let cardSurface = Color(light: Color(hex: "#fbfaf6"), dark: Color.white.opacity(0.025))
    static let cardBorder = Color(light: Color.black.opacity(0.07), dark: Color.white.opacity(0.07))
    static let kpiSurface = Color(light: Color.black.opacity(0.025), dark: Color.white.opacity(0.04))

    // MARK: - Foreground (label hierarchy)
    static let label  = Color(light: Color.black.opacity(0.88), dark: Color.white.opacity(0.92))
    static let label2 = Color(light: Color.black.opacity(0.56), dark: Color.white.opacity(0.56))
    static let label3 = Color(light: Color.black.opacity(0.42), dark: Color.white.opacity(0.38))
    static let label4 = Color(light: Color.black.opacity(0.28), dark: Color.white.opacity(0.22))

    // MARK: - Selection
    static let rowHover    = Color(light: Color.black.opacity(0.035), dark: Color.white.opacity(0.04))
    static let rowSelected = Color(light: Color.black.opacity(0.07),  dark: Color.white.opacity(0.08))
    static let accentTint  = Color.accentColor.opacity(0.12)

    // MARK: - Semantic colors
    static let dueSoon = Color(light: Color(hex: "#c44d3c"), dark: Color(hex: "#ff7b6b"))
    static let dueSoonBg = Color(light: Color(hex: "#c44d3c").opacity(0.14), dark: Color(hex: "#ff7b6b").opacity(0.18))

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
