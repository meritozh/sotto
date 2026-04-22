import SwiftUI

struct ContentView: View {
    #if os(iOS)
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    #endif

    var body: some View {
        #if os(macOS)
        DesktopLayout()
        #else
        if horizontalSizeClass == .regular {
            DesktopLayout()
        } else {
            TabRootView()
        }
        #endif
    }
}

/// Two-column NavigationSplitView + overlay panel.
/// Shared by macOS and iPad.
struct DesktopLayout: View {

    // MARK: - Properties

    @State private var selectedDestination: SidebarDestination? = .dashboard
    @State private var selectedSubscription: Subscription?

    // MARK: - Body

    var body: some View {
        NavigationSplitView {
            SidebarView(selection: $selectedDestination)
                #if os(macOS)
                .navigationSplitViewColumnWidth(min: 180, ideal: 200, max: 220)
                #endif
        } detail: {
            detailContent
                .overlay {
                    if selectedSubscription != nil {
                        SubscriptionDetailOverlay(selectedSubscription: $selectedSubscription)
                    }
                }
        }
        #if os(macOS)
        .frame(minWidth: 900, minHeight: 500)
        #endif
        .onChange(of: selectedDestination) { _, _ in
            selectedSubscription = nil
        }
    }

    // MARK: - Private Views

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
