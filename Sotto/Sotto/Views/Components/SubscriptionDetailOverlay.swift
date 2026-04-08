import SwiftUI

struct SubscriptionDetailOverlay: View {
    @Binding var selectedSubscription: Subscription?

    var body: some View {
        ZStack(alignment: .trailing) {
            // Dimming background
            if selectedSubscription != nil {
                Color.black.opacity(0.15)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            selectedSubscription = nil
                        }
                    }
            }

            // Slide-in panel
            if let subscription = selectedSubscription {
                InspectorPane(subscription: subscription, onClose: {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        selectedSubscription = nil
                    }
                })
                .frame(width: 320)
                .background(.regularMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: .black.opacity(0.2), radius: 8, x: -2)
                .padding(.vertical, 8)
                .padding(.trailing, 8)
                .transition(.move(edge: .trailing))
            }
        }
        .animation(.easeInOut(duration: 0.25), value: selectedSubscription?.id)
    }
}
