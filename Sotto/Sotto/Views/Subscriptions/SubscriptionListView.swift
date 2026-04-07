import SwiftUI
import SwiftData

struct SubscriptionListView: View {
    @Query(sort: \Subscription.nextDueDate) private var subscriptions: [Subscription]
    @Query private var categories: [Category]
    @Binding var selectedSubscription: Subscription?
    @State private var searchText = ""
    @State private var statusFilter: SubscriptionStatus? = .active
    @State private var categoryFilter: Category?
    @State private var showAddSheet = false

    private var filteredSubscriptions: [Subscription] {
        subscriptions.filter { sub in
            let matchesSearch = searchText.isEmpty || sub.name.localizedCaseInsensitiveContains(searchText)
            let matchesStatus = statusFilter == nil || sub.status == statusFilter
            let matchesCategory = categoryFilter == nil || sub.category?.id == categoryFilter?.id
            return matchesSearch && matchesStatus && matchesCategory
        }
    }

    var body: some View {
        List(filteredSubscriptions, selection: $selectedSubscription) { subscription in
            SubscriptionRow(subscription: subscription)
                .tag(subscription)
                .contextMenu {
                    if subscription.status == .active {
                        Button("Pause") { subscription.status = .paused; subscription.updatedAt = Date() }
                    }
                    if subscription.status == .paused {
                        Button("Resume") { subscription.status = .active; subscription.updatedAt = Date() }
                    }
                    if subscription.status != .cancelled {
                        Button("Cancel Subscription") { subscription.status = .cancelled; subscription.updatedAt = Date() }
                    }
                    Divider()
                    Button("Delete", role: .destructive) { deleteSubscription(subscription) }
                }
        }
        .searchable(text: $searchText, prompt: "Search subscriptions")
        .toolbar {
            ToolbarItem {
                Button {
                    showAddSheet = true
                } label: {
                    Label("Add Subscription", systemImage: "plus")
                }
            }
            ToolbarItem {
                Picker("Status", selection: $statusFilter) {
                    Text("All").tag(nil as SubscriptionStatus?)
                    ForEach(SubscriptionStatus.allCases, id: \.self) { status in
                        Text(status.displayName).tag(status as SubscriptionStatus?)
                    }
                }
            }
            ToolbarItem {
                Picker("Category", selection: $categoryFilter) {
                    Text("All Categories").tag(nil as Category?)
                    ForEach(categories) { category in
                        Text(category.name).tag(category as Category?)
                    }
                }
            }
        }
        .sheet(isPresented: $showAddSheet) {
            AddSubscriptionSheet()
        }
        .navigationTitle("All Subscriptions")
    }

    @Environment(\.modelContext) private var modelContext

    private func deleteSubscription(_ subscription: Subscription) {
        if selectedSubscription?.id == subscription.id {
            selectedSubscription = nil
        }
        modelContext.delete(subscription)
    }
}
