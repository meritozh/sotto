import SwiftUI

struct InspectorPane: View {
    let subscription: Subscription

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(subscription.name)
                .font(.title2)
                .fontWeight(.bold)
            Text("Inspector details — coming in Task 8")
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding()
    }
}
