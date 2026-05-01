import SwiftUI

struct CardModifier: ViewModifier {
    var paddingH: CGFloat = 18
    var paddingV: CGFloat = 16

    func body(content: Content) -> some View {
        content
            .padding(.horizontal, paddingH)
            .padding(.vertical, paddingV)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: DesignTokens.cardCornerRadius)
                    .fill(DesignTokens.cardSurface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.cardCornerRadius)
                    .strokeBorder(DesignTokens.cardBorder, lineWidth: 0.5)
            )
            .shadow(
                color: .black.opacity(DesignTokens.cardShadowOpacity),
                radius: DesignTokens.cardShadowRadius,
                y: DesignTokens.cardShadowOffsetY
            )
    }
}

extension View {
    func cardStyle(paddingH: CGFloat = 18, paddingV: CGFloat = 16) -> some View {
        modifier(CardModifier(paddingH: paddingH, paddingV: paddingV))
    }

    func cardSectionHeader() -> some View {
        self
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(DesignTokens.label3)
            .textCase(nil)
            .kerning(0.2)
    }
}

#Preview {
    VStack(alignment: .leading, spacing: 4) {
        HStack(spacing: 6) {
            Circle().fill(DesignTokens.label4).frame(width: 6, height: 6)
            Text("Monthly spending").cardSectionHeader()
        }
        Text("¥1,204")
            .font(.system(size: 38, weight: .semibold, design: .default))
            .monospacedDigit()
    }
    .cardStyle()
    .frame(width: 320)
    .padding()
    .background(DesignTokens.windowBackground)
}
