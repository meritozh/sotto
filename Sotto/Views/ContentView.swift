import SwiftUI

struct ContentView: View {

    @State private var selectedDestination: SidebarDestination = .dashboard
    @State private var showAddSubscriptionSheet = false

    var body: some View {
        TabView(selection: $selectedDestination) {
            Tab("Dashboard", systemImage: "square.grid.2x2", value: SidebarDestination.dashboard) {
                NavigationStack {
                    DashboardView(onAddSubscription: triggerAddSubscription)
                }
            }
            Tab("Subscriptions", systemImage: "list.bullet", value: SidebarDestination.subscriptions) {
                NavigationStack {
                    SubscriptionListView(showAddSheet: $showAddSubscriptionSheet)
                }
            }
            Tab("Calendar", systemImage: "calendar", value: SidebarDestination.calendar) {
                NavigationStack {
                    CalendarView()
                }
            }
            Tab("Categories", systemImage: "tag", value: SidebarDestination.categories) {
                NavigationStack {
                    CategoriesView()
                }
            }
            Tab("Settings", systemImage: "gearshape", value: SidebarDestination.settings) {
                NavigationStack {
                    SettingsView()
                }
            }
        }
        .tabViewStyle(.sidebarAdaptable)
        .sheet(isPresented: $showAddSubscriptionSheet) {
            AddSubscriptionSheet()
        }
    }

    private func triggerAddSubscription() {
        selectedDestination = .subscriptions
        showAddSubscriptionSheet = true
    }
}

#Preview {
    ContentView()
        .modelContainer(makePreviewContainer())
}
