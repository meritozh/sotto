import SwiftUI

struct SubscriptionDetailOverlay: View {

    // MARK: - Properties

    @Binding var selectedSubscription: Subscription?
    private let panelPadding: CGFloat = 8

    // MARK: - Body

    var body: some View {
        GeometryReader { geometry in
            let panelWidth = max(0, min(320, geometry.size.width - (panelPadding * 2)))

            ZStack(alignment: .trailing) {
                // Dimming background
                if selectedSubscription != nil {
                    Color.black.opacity(0.15)
                        .ignoresSafeArea()
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: AppConstants.overlayAnimationDuration)) {
                                selectedSubscription = nil
                            }
                        }
                }

                // Slide-in panel
                if let subscription = selectedSubscription {
                    InspectorPane(subscription: subscription, onClose: {
                        withAnimation(.easeInOut(duration: AppConstants.overlayAnimationDuration)) {
                            selectedSubscription = nil
                        }
                    })
                    .frame(width: panelWidth)
                    .background(DesignTokens.cardSurface)
                    .glassEffect(.regular, in: .rect(cornerRadius: DesignTokens.radiusLG))
                    .clipShape(RoundedRectangle(cornerRadius: DesignTokens.radiusLG, style: .continuous))
                    .shadow(color: .black.opacity(0.12), radius: 6, x: -1)
                    .padding(.vertical, panelPadding)
                    .padding(.trailing, panelPadding)
                    .transition(.move(edge: .trailing))
                }
            }
        }
        .animation(.easeInOut(duration: AppConstants.overlayAnimationDuration), value: selectedSubscription?.id)
    }
}

#Preview {
    @Previewable @State var sub: Subscription? = makeSampleSubscription()
    SubscriptionDetailOverlay(selectedSubscription: $sub)
        .frame(width: 600, height: 400)
}
