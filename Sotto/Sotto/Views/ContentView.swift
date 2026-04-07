import SwiftUI

struct ContentView: View {
    @State private var selectedDestination: SidebarDestination? = .dashboard
    @State private var selectedSubscription: Subscription?
    @State private var showInspector = false

    var body: some View {
        NavigationSplitView {
            SidebarView(selection: $selectedDestination)
                .navigationSplitViewColumnWidth(min: 180, ideal: 220, max: 280)
        } detail: {
            switch selectedDestination {
            case .dashboard:
                DashboardView()
            case .subscriptions:
                SubscriptionListView(selectedSubscription: $selectedSubscription)
            case .calendar:
                CalendarView(selectedSubscription: $selectedSubscription)
            case .categories:
                Text("Categories — coming soon")
            case .settings:
                Text("Settings — coming soon")
            case nil:
                Text("Select a section")
                    .foregroundStyle(.secondary)
            }
        }
        .frame(minWidth: 700, minHeight: 500)
        .inspector(isPresented: $showInspector) {
            if let subscription = selectedSubscription {
                InspectorPane(subscription: subscription)
                    .inspectorColumnWidth(min: 250, ideal: 300, max: 350)
            }
        }
        .onChange(of: selectedSubscription) { _, newValue in
            showInspector = newValue != nil
        }
    }
}
