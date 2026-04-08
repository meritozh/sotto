import SwiftUI

struct ContentView: View {
    @State private var selectedDestination: SidebarDestination? = .dashboard
    @State private var selectedSubscription: Subscription?

    var body: some View {
        NavigationSplitView {
            SidebarView(selection: $selectedDestination)
                .navigationSplitViewColumnWidth(min: 180, ideal: 200)
        } detail: {
            #if os(macOS)
            HSplitView {
                detailContent
                    .frame(minWidth: 400)

                if let subscription = selectedSubscription {
                    InspectorPane(subscription: subscription)
                        .frame(minWidth: 250, idealWidth: 300, maxWidth: 350)
                }
            }
            #else
            detailContent
            #endif
        }
        #if os(macOS)
        .frame(minWidth: 800, minHeight: 500)
        #endif
        .onChange(of: selectedDestination) { _, _ in
            selectedSubscription = nil
        }
    }

    @ViewBuilder
    private var detailContent: some View {
        switch selectedDestination {
        case .dashboard:
            DashboardView()
        case .subscriptions:
            SubscriptionListView(selectedSubscription: $selectedSubscription)
        case .calendar:
            CalendarView(selectedSubscription: $selectedSubscription)
        case .categories:
            CategoriesView()
        case .settings:
            SettingsView()
        case nil:
            Text("Select a section")
                .foregroundStyle(.secondary)
        }
    }
}
