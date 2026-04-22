import SwiftUI

struct CardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: DesignTokens.cardCornerRadius)
                    .fill(.background)
            )
            .shadow(
                color: .black.opacity(DesignTokens.cardShadowOpacity),
                radius: DesignTokens.cardShadowRadius,
                y: DesignTokens.cardShadowOffsetY
            )
    }
}

extension View {
    func cardStyle() -> some View {
        modifier(CardModifier())
    }
}
