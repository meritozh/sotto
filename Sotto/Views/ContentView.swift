import SwiftUI

public struct ContentView: View {

    @State private var selectedDestination: SidebarDestination = .dashboard
    @State private var lastContentDestination: SidebarDestination = .dashboard
    @State private var showAddSubscriptionSheet = false

    public init() {}

    public var body: some View {
        tabs
        .sheet(isPresented: $showAddSubscriptionSheet) {
            AddSubscriptionSheet()
        }
    }

    private var tabs: some View {
        TabView(selection: tabSelection) {
            Tab("Dashboard", systemImage: "square.grid.2x2", value: SidebarDestination.dashboard) {
                NavigationStack {
                    DashboardView()
                }
            }
            Tab("Subscriptions", systemImage: "list.bullet", value: SidebarDestination.subscriptions) {
                NavigationStack {
                    SubscriptionListView(showAddSheet: $showAddSubscriptionSheet)
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
            #if os(iOS)
            Tab(value: SidebarDestination.addSubscription, role: .search) {
                Color.clear
            } label: {
                Label("Add Subscription", systemImage: "plus")
                    .labelStyle(.iconOnly)
                    .accessibilityLabel("Add Subscription")
            }
            .tabPlacement(.pinned)
            #endif
        }
        .tabViewStyle(.sidebarAdaptable)
        #if os(iOS)
        .tabBarMinimizeBehavior(.onScrollDown)
        #endif
    }

    private var tabSelection: Binding<SidebarDestination> {
        Binding {
            selectedDestination
        } set: { newValue in
            if newValue == .addSubscription {
                selectedDestination = lastContentDestination
                showAddSubscriptionSheet = true
            } else {
                selectedDestination = newValue
                lastContentDestination = newValue
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(makePreviewContainer())
}
