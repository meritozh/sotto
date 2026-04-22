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
                    .background(.regularMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(color: .black.opacity(0.2), radius: 8, x: -2)
                    .padding(.vertical, panelPadding)
                    .padding(.trailing, panelPadding)
                    .transition(.move(edge: .trailing))
                }
            }
        }
        .animation(.easeInOut(duration: AppConstants.overlayAnimationDuration), value: selectedSubscription?.id)
    }
}
