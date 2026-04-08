import SwiftUI

struct TabRootView: View {
    @State private var selectedTab = 0
    @State private var selectedSubscription: Subscription?

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                DashboardView()
            }
            .tabItem { Label("Dashboard", systemImage: "square.grid.2x2") }
            .tag(0)

            NavigationStack {
                SubscriptionListView(selectedSubscription: $selectedSubscription)
                    .navigationDestination(item: $selectedSubscription) { subscription in
                        InspectorPane(subscription: subscription)
                    }
            }
            .tabItem { Label("Subscriptions", systemImage: "list.bullet") }
            .tag(1)

            NavigationStack {
                CalendarView(selectedSubscription: $selectedSubscription)
                    .navigationDestination(item: $selectedSubscription) { subscription in
                        InspectorPane(subscription: subscription)
                    }
            }
            .tabItem { Label("Calendar", systemImage: "calendar") }
            .tag(2)

            NavigationStack {
                CategoriesView()
            }
            .tabItem { Label("Categories", systemImage: "tag") }
            .tag(3)

            NavigationStack {
                SettingsView()
            }
            .tabItem { Label("Settings", systemImage: "gearshape") }
            .tag(4)
        }
        .onChange(of: selectedTab) { _, _ in
            selectedSubscription = nil
        }
    }
}
